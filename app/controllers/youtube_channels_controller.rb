class YoutubeChannelsController < ApplicationController
  before_action :set_youtube_channel, only: [:show, :edit, :update, :destroy, :phone_usage, :set, :regenerate_channel_art]
  DEFAULT_LIMIT = 25

  # GET /youtube_channels
  # GET /youtube_channels.json
  def index
    if params[:filter].present?
      unless params[:filter][:order].present?
        params[:filter][:order] = "publication_date"
      end
      unless params[:filter][:order_type].present?
        params[:filter][:order_type] = "asc"
      end
    else
      params[:filter] = {order: "publication_date", order_type: "desc" }
    end
    params[:youtube_channel_name].strip! if params[:youtube_channel_name].present?
    nulls_last = " NULLS LAST"
    order_by = "youtube_channels."
    unless %w{id channel_type youtube_channel_name youtube_channel_id is_active is_verified_by_phone linked filled ready blocked client publication_date filling_date updated_at strike}.include?(params[:filter][:order])
      if params[:filter][:order] == "tier"
        order_by = "geobase_localities.population"
      else
        order_by =  "geobase_" + params[:filter][:order].pluralize + ".name"
      end
      if params[:filter][:order] == "email"
        order_by = "email_accounts.email"
      end
    else
      if params[:filter][:order] == "client"
        order_by = "clients.name"
      else
        order_by += params[:filter][:order]
      end
      nulls_last = "" if %w{linked is_active is_verified_by_phone filled ready blocked channel_type strike}.include?(params[:filter][:order])
    end
    if params[:unlinked].present? && params[:unlinked] == "true"
      @youtube_channels = YoutubeChannel.includes(google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}])
      .where("youtube_channels.youtube_channel_id IS NULL AND youtube_channels.linked IS NOT TRUE AND google_account_id IS NOT NULL AND email_accounts.account_type = ?", EmailAccount.account_type.find_value(:operational).value)
      .references(google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}])
    else
      params[:limit] = DEFAULT_LIMIT unless params[:limit].present?
      column_names = YoutubeChannel.column_names
      column_names.delete("yt_stat_json")
      column_names_string = "youtube_channels." + column_names.join(",youtube_channels.")
      @youtube_channels = YoutubeChannel.unscoped.distinct.select("#{column_names_string}, #{order_by}").joins(
          "LEFT OUTER JOIN google_accounts ON google_accounts.id = youtube_channels.google_account_id
          LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id
          LEFT OUTER JOIN geobase_localities ON geobase_localities.id = email_accounts.locality_id
          LEFT OUTER JOIN geobase_regions ON geobase_regions.id = geobase_localities.primary_region_id
          LEFT OUTER JOIN geobase_countries ON geobase_countries.id = geobase_regions.country_id
          LEFT OUTER JOIN geobase_regions regions ON regions.id = email_accounts.region_id
          LEFT OUTER JOIN geobase_countries countries ON countries.id = regions.country_id
          LEFT OUTER JOIN clients ON clients.id = email_accounts.client_id
          #{'RIGHT JOIN yt_statistics on youtube_channels.id = yt_statistics.resource_id AND yt_statistics.resource_type = \'YoutubeChannel\'' if params[:has_duplicate_videos].present?}
          #{'RIGHT JOIN associated_websites ON youtube_channels.id = associated_websites.youtube_channel_id' if params[:associated].present?}
          #{'LEFT JOIN phone_usages ON youtube_channels.id = phone_usages.phone_usageable_id AND phone_usages.phone_usageable_type = \'YoutubeChannel\'' if params[:created_by_phone].present?}"
        )
        .by_display_all(params[:display_all])
        .by_id(params[:id])
        .by_youtube_channel_name(params[:youtube_channel_name])
        .by_youtube_channel_id(params[:youtube_channel_id])
        .by_email(params[:email])
        .by_tier(params[:tier])
        .by_locality_id(params[:locality_id])
        .by_region_id(params[:region_id])
        .by_linked(params[:linked])
        .by_filled(params[:filled])
        .by_ready(params[:ready])
        .by_blocked(params[:blocked])
        .by_is_active(params[:is_active])
        .by_gmail_is_active(params[:gmail_is_active])
        .by_is_verified_by_phone(params[:is_verified_by_phone])
        .by_strike(params[:strike])
        .by_has_duplicate_videos(params[:has_duplicate_videos])
        .by_associated_websites(params[:associated])
        .by_channel_type(params[:channel_type])
        .by_all_videos_privacy(params[:all_videos_privacy])
        .by_country_id(params[:country_id])
        .by_client_id(params[:client_id])
        .by_bot_server_id(params[:bot_server_id])
        .by_created_by_phone(params[:created_by_phone])
        .by_last_event_time(params[:table_name], params[:field_name], params[:last_time])
        .where("email_accounts.account_type = ?", EmailAccount.account_type.find_value(:operational).value)
        .page(params[:page]).per(params[:limit])
        .order(order_by + " " + params[:filter][:order_type] + nulls_last)
    end
    respond_to do |format|
      format.html
      format.json{
        json_text = []
        @youtube_channels.each do |yc|
          json_object = {}
          json_object[:id] = yc.google_account.try(:google_account_activity).try(:id)
          json_object[:email_account_id] = yc.google_account.try(:email_account).try(:id)
          json_object[:email] = yc.google_account.try(:email_account).try(:email)
          json_object[:password] = yc.google_account.try(:email_account).try(:password)
          json_object[:ip] = yc.google_account.try(:email_account).try(:ip_address).try(:address)
          json_text << json_object
        end
        render :json => json_text.to_json
      }
    end
  end

  # GET /youtube_channels/1
  # GET /youtube_channels/1.json
  def show
    respond_to do |format|
      format.html
      format.json{
        # if !@youtube_channel.linked
        #   @youtube_channel.linked = true
        #   @youtube_channel.save
        # end
        json_object = @youtube_channel.json
        url =  if request.domain == "localhost"
            request.protocol + request.host_with_port
          else
            request.protocol + request.host
          end
				json_object[:phone_number] = if @youtube_channel.google_account.email_account.recovery_phone.present? && @youtube_channel.google_account.email_account.recovery_phone_assigned
					@youtube_channel.google_account.email_account.recovery_phone.value
				else
					@youtube_channel.phone_number.present? ? @youtube_channel.phone_number : ""
				end
        json_object[:channel_icon_url] = !@youtube_channel.channel_icon.blank? ? URI::escape(url + @youtube_channel.channel_icon.url(:original), '[]') : ""
        json_object[:channel_art_url] =  !@youtube_channel.channel_art.blank? ? URI::escape(url + @youtube_channel.channel_art.url(:original), '[]') : ""
        render :json => json_object.to_json
      }
    end
  end

  # GET /youtube_channels/new
  def new
    @youtube_channel = YoutubeChannel.new
    @youtube_channel.channel_links = '{"links": []}'
  end

  # GET /youtube_channels/1/edit
  def edit
    @youtube_channel.channel_links = '{"links": []}' unless @youtube_channel.channel_links.present?
    @channel_links = JSON.parse(@youtube_channel.channel_links)
    @associated_websites = @youtube_channel.associated_websites.sort
  end

  # POST /youtube_channels
  # POST /youtube_channels.json
  def create
    @youtube_channel = YoutubeChannel.new(youtube_channel_params)

    respond_to do |format|
      if @youtube_channel.save
        format.html { redirect_to youtube_channels_path, notice: 'Youtube channel was successfully created.' }
        format.json { render action: 'show', status: :created, location: @youtube_channel }
      else
        format.html { render action: 'new' }
        format.json { render json: @youtube_channel.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /youtube_channels/1
  # PATCH/PUT /youtube_channels/1.json
  def update
    respond_to do |format|
      if @youtube_channel.update(youtube_channel_params)
        format.html { redirect_to youtube_channels_path, notice: 'Youtube channel successfully updated.' }
        response = {status: 200}
        format.json { render json: response, status: response[:status] }
      else
        @associated_websites = @youtube_channel.associated_websites.sort
        format.html { render action: 'edit' }
        format.json { render json: @youtube_channel.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /youtube_channels/1
  # DELETE /youtube_channels/1.json
  def destroy
    @youtube_channel.destroy
    respond_to do |format|
      format.html { redirect_to youtube_channels_url, notice: 'Youtube channel was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  def regenerate_channel_art
    @youtube_channel.generate_art if @youtube_channel.channel_type.business?
    respond_to do |format|
      format.html { redirect_to :back, notice: "Channel art was successfully regenerated" }
      format.json { head :no_content }
    end
  end

  def json_list
    @youtube_accounts = if params[:id].present?
      YoutubeChannel.includes(google_account: [:email_account]).distinct.where("youtube_channels.id = ?",
      params[:id])
    else
      YoutubeChannel.includes({google_account: [:email_account]}).distinct.where("(CAST(youtube_channels.id as text) LIKE ? OR
        LOWER(email_accounts.email) LIKE ? OR LOWER(youtube_channels.youtube_channel_name) LIKE ?) AND
      email_accounts.email_item_type = 'GoogleAccount' AND
      youtube_channels.is_active=true AND youtube_channels.linked=true AND
      youtube_channels.youtube_channel_id IS NOT NULL AND youtube_channels.youtube_channel_id <> ''",
      "#{params[:q].strip}%", "%#{params[:q].strip.downcase}%", "%#{params[:q].strip.downcase}%").order(:youtube_channel_name)
    end
    render json: @youtube_accounts.map { |e| {id: e.id, text: "#{e.id} #{' | ' + e.youtube_channel_name if e.youtube_channel_name.present?} #{' | ' + e.google_account.email_account.try(:email) if e.google_account && e.google_account.email_account}"} }
  end

  def phone_usage
		response = if params[:service].present?
			PhoneUsage.create_from_params(params, @youtube_channel)
			{status: 200}
		else
			{status: 500}
		end
		render json: response, status: response[:status]
	end

  def set
    @youtube_channel.youtube_channel_id = params[:youtube_channel_id].strip if params[:youtube_channel_id].present?
    @youtube_channel.is_active = params[:is_active] if params[:is_active].present?
    @youtube_channel.is_verified_by_phone = params[:is_verified_by_phone] if params[:is_verified_by_phone].present?
		@youtube_channel.phone_number = params[:phone_number] if params[:phone_number].present?
    @youtube_channel.linked = params[:linked] if params[:linked].present?
    @youtube_channel.blocked = params[:blocked] if params[:blocked].present?
    if params[:filled].present?
      @youtube_channel.filled = params[:filled]
      @youtube_channel.fields_to_update = "" if params[:filled] == true.to_s
    end
    if params[:save_filling_date].present? && params[:save_filling_date] == "true"
      @youtube_channel.filling_date = Time.now
      Utils.delay(queue: DelayedJobQueue::OTHER, priority: DelayedJobPriority::HIGH).save_web_screenshot(@youtube_channel, @youtube_channel.url) if @youtube_channel.url.present?
    end
    @youtube_channel.publication_date = Time.now if params[:save_publication_date].present? && params[:save_publication_date] == "true"
    @youtube_channel.delay(queue: DelayedJobQueue::SAVE_SCREENSHOT, priority: 1).save_screenshot if params[:save_screenshot].present? && params[:save_screenshot] == "true"
    if params[:all_videos_privacy].present?
      YoutubeVideo.where("youtube_channel_id = ?", @youtube_channel.id).update_all(privacy_level: YoutubeChannel.all_videos_privacy.find_value(params[:all_videos_privacy]).value)
      @youtube_channel.all_videos_privacy = nil
    end
    response = if @youtube_channel.save
      if params[:blocked].to_s == "true" && @youtube_channel.blocked
        BotServer.kill_all_zenno
        BroadcasterMailer.new_blocked_youtube_channel(@youtube_channel.id)
        Utils.pushbullet_broadcast("New blocked youtube channel!", "Please check new blocked youtube channel #{Rails.configuration.routes_default_url_options[:host]}#{Rails.application.routes.url_helpers.youtube_channels_path(id: @youtube_channel.id)}")
      end
      {status: 200}
    else
      {status: 500}
    end
    render json: response, status: response[:status]
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_youtube_channel
      @youtube_channel = YoutubeChannel.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def youtube_channel_params
      params[:youtube_channel][:youtube_channel_id] = nil if params[:youtube_channel] && params[:youtube_channel][:youtube_channel_id].try(:strip).blank?
      params.require(:youtube_channel).permit!
    end
end
