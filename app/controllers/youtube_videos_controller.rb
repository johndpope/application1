class YoutubeVideosController < ApplicationController
	before_action :set_youtube_video, only: [:show, :edit, :update, :destroy, :set, :regenerate_video_thumbnail, :reblend]
	DEFAULT_LIMIT = 25

	# GET /youtube_videos
	# GET /youtube_videos.json
	def index
		if params[:filter].present?
			params[:filter][:order] = 'publication_date' unless params[:filter][:order].present?
			params[:filter][:order_type] = 'asc' unless params[:filter][:order_type].present?
		else
			params[:filter] = { order: 'publication_date', order_type: 'desc' }
		end

		params[:youtube_channel_name].strip! if params[:youtube_channel_name].present?
		nulls_last = ' NULLS LAST'
		order_by = 'youtube_videos.'
		unless %w{id title youtube_video_id is_active linked ready deleted posted_on_google_plus client publication_date updated_at}.include?(params[:filter][:order])
			if params[:filter][:order] == 'tier'
				order_by = 'geobase_localities.population'
			else
				order_by = 'geobase_' + params[:filter][:order].pluralize + '.name'
			end

			order_by = 'email_accounts.email' if params[:filter][:order] == 'email'
			order_by = 'youtube_channels.youtube_channel_name' if params[:filter][:order] == 'youtube_channel_name'
		else
			if params[:filter][:order] == 'client'
				order_by = 'clients.name'
			else
				order_by += params[:filter][:order]
			end

			nulls_last = '' if %w{linked is_active ready deleted posted_on_google_plus}.include?(params[:filter][:order])
		end

    params[:limit] = DEFAULT_LIMIT unless params[:limit].present?
    column_names = YoutubeVideo.column_names
    column_names.delete("yt_stat_json")
    column_names_string = "youtube_videos." + column_names.join(",youtube_videos.")
		@youtube_videos = YoutubeVideo.unscoped.distinct.select("#{column_names_string}, #{order_by}").joins(
        "LEFT OUTER JOIN youtube_channels ON youtube_channels.id = youtube_videos.youtube_channel_id
        LEFT OUTER JOIN google_accounts ON google_accounts.id = youtube_channels.google_account_id
        LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id
        LEFT OUTER JOIN geobase_localities ON geobase_localities.id = email_accounts.locality_id
        LEFT OUTER JOIN geobase_regions ON geobase_regions.id = geobase_localities.primary_region_id
        LEFT OUTER JOIN geobase_countries ON geobase_countries.id = geobase_regions.country_id
        LEFT OUTER JOIN geobase_regions regions ON regions.id = email_accounts.region_id
        LEFT OUTER JOIN geobase_countries countries ON countries.id = regions.country_id
        LEFT OUTER JOIN clients ON clients.id = email_accounts.client_id
  			LEFT OUTER JOIN youtube_video_annotations ON youtube_video_annotations.youtube_video_id = youtube_videos.id
        LEFT OUTER JOIN youtube_video_cards ON youtube_video_cards.youtube_video_id = youtube_videos.id
        LEFT OUTER JOIN call_to_action_overlays ON call_to_action_overlays.youtube_video_id = youtube_videos.id
        #{'RIGHT JOIN yt_statistics on youtube_videos.id = yt_statistics.resource_id AND yt_statistics.resource_type = \'YoutubeVideo\'' if params[:grab_statistics_succeded].present? || params[:processed].present? || params[:grab_statistics_error_type].present?}"
      )
  		.by_display_all(params[:display_all])
  		.by_id(params[:id])
      .by_youtube_channel_id(params[:youtube_channel_id])
  		.by_title(params[:title])
  		.by_youtube_channel_name(params[:youtube_channel_name])
  		.by_youtube_video_id(params[:youtube_video_id])
  		.by_email(params[:email])
  		.by_tier(params[:tier])
  		.by_locality_id(params[:locality_id])
  		.by_region_id(params[:region_id])
  		.by_linked(params[:linked])
  		.by_is_active(params[:is_active])
      .by_channel_is_active(params[:channel_is_active])
      .by_gmail_is_active(params[:gmail_is_active])
      .by_channel_is_verified(params[:channel_is_verified])
      .by_has_youtube_video_id(params[:has_youtube_video_id])
  		.by_country_id(params[:country_id])
  		.by_client_id(params[:client_id])
      .by_bot_server_id(params[:bot_server_id])
  		.by_ready(params[:ready])
      .by_deleted(params[:deleted])
      .by_grab_statistics_succeded(params[:grab_statistics_succeded])
      .by_grab_statistics_error_type(params[:grab_statistics_error_type])
      .by_processed(params[:processed])
      .by_posted_annotations(params[:annotations_posted])
      .by_posted_cards(params[:cards_posted])
      .by_posted_call_to_action_overlays(params[:call_to_action_overlays_posted])
      .by_posted_on_google_plus(params[:posted_on_google_plus])
      .by_last_event_time(params[:table_name], params[:field_name], params[:last_time])
  		.page(params[:page]).per(params[:limit])
  		.order(order_by + ' ' + params[:filter][:order_type] + nulls_last)

		respond_to do |format|
			format.html
			format.json {
				json_text = []
				@youtube_videos.each do |yv|
					json_object = {}
					ga = yv.try(:youtube_channel).try(:google_account)
          ea = ga.try(:email_account)
					json_object[:id] = GoogleAccountActivity.find_by_google_account_id(ga.id).try(:id)
					json_object[:email_account_id] = ea.try(:id)
					json_object[:email] = ea.try(:email)
					json_object[:password] = ea.try(:password)
					json_object[:ip] = ea.try(:ip_address).try(:address)
					json_text << json_object
				end
				render :json => json_text.uniq.to_json
			}
		end
	end

	# GET /youtube_videos/1
	# GET /youtube_videos/1.json
	def show
		respond_to do |format|
			format.html
			format.json {
				json_text = @youtube_video.json

				url = if request.domain == 'localhost'
					request.protocol + request.host_with_port
				else
					request.protocol + request.host
				end

				json_text['thumbnail_url'] = @youtube_video.thumbnail.present? ? URI::escape(url + @youtube_video.thumbnail.url(:original), '[]') : ''
        json_text["video_full_path"] = @youtube_video.blended_video.present? && @youtube_video.blended_video.file.present? ? URI::escape(url + @youtube_video.blended_video.file.url(:original), '[]') : ""
				render :json => json_text.to_json
			}
		end
	end

	# GET /youtube_videos/new
	def new
		@youtube_video = YoutubeVideo.new
		@youtube_video.allow_comments = :all
	end

	# GET /youtube_videos/1/edit
	def edit
		@youtube_video_annotations = @youtube_video.youtube_video_annotations.sort
		@youtube_video_cards = @youtube_video.youtube_video_cards.sort
    @youtube_video_search_phrases = @youtube_video.youtube_video_search_phrases.sort
	end

	# POST /youtube_videos
	# POST /youtube_videos.json
	def create
		@youtube_video = YoutubeVideo.new(youtube_video_params)

		respond_to do |format|
			if @youtube_video.save
				format.html { redirect_to youtube_videos_path, notice: 'Youtube video was successfully created.' }
				format.json { render action: 'show', status: :created, location: @youtube_video }
			else
				@youtube_video.thumbnail = nil
				format.html { render action: 'new' }
				format.json { render json: @youtube_video.errors, status: :unprocessable_entity }
			end
		end
	end

	# PATCH/PUT /youtube_videos/1
	# PATCH/PUT /youtube_videos/1.json
	def update
		respond_to do |format|
			if @youtube_video.update(youtube_video_params)
				format.html { redirect_to youtube_videos_path, notice: 'Youtube video was successfully updated.' }
				response = { status: 200 }
				format.json { render json: response, status: response[:status] }
			else
				@youtube_video_annotations = @youtube_video.youtube_video_annotations.sort
				@youtube_video_cards = @youtube_video.youtube_video_cards.sort
				format.html { render action: 'edit' }
				format.json { render json: @youtube_video.errors, status: :unprocessable_entity }
			end
		end
	end

	# DELETE /youtube_videos/1
	# DELETE /youtube_videos/1.json
	def destroy
		@youtube_video.destroy

		respond_to do |format|
			format.html { redirect_to youtube_videos_url, notice: 'Youtube video was successfully deleted.' }
			format.json { head :no_content }
		end
	end

  def reblend
    @already_in_queue = if @youtube_video.blended_video.present? && !Delayed::Job.where(queue: DelayedJobQueue::BLEND_VIDEO_SET).where("handler like ?","%blended_video_id: #{@youtube_video.blended_video_id}\n%").exists?
      Delayed::Job.enqueue BlendedVideos::ForceBlendJob.new(@youtube_video.blended_video_id), queue: DelayedJobQueue::BLEND_VIDEO_SET
      false
    else
      true
    end
    respond_to do |format|
			format.js
		end
  end

	def set
		response = if true
      if params.keys.include?("youtube_video_id")
			  @youtube_video.youtube_video_id = if params[:youtube_video_id].present?
          params[:youtube_video_id].strip
        else
          @youtube_video.posting_time = nil
          unless Delayed::Job.where(queue: DelayedJobQueue::BLEND_VIDEO_SET).where("handler like ?","%blended_video_id: #{@youtube_video.blended_video_id}\n%").exists?
      			Delayed::Job.enqueue BlendedVideos::ForceBlendJob.new(@youtube_video.blended_video_id), queue: DelayedJobQueue::BLEND_VIDEO_SET
      		end
          @youtube_video.posted_on_google_plus = false
          @youtube_video.google_plus_upload_time = nil
          @youtube_video.reset_post_production
          nil
        end
      end
      if params[:update_yt_status].present? && params[:update_yt_status] == "true" && Setting.get_value_by_name("YoutubeService::YOUTUBE_STATISTICS_ENABLED") == "true"
        random_system_account = EmailAccount.joins('LEFT OUTER JOIN ip_addresses ON ip_addresses.id = email_accounts.ip_address_id LEFT OUTER JOIN google_accounts ON email_accounts.email_item_id = google_accounts.id LEFT OUTER JOIN google_account_activities ON google_accounts.id = google_account_activities.google_account_id').by_display_all("true").by_is_active("true").by_account_type(EmailAccount.account_type.find_value(:system).value.to_s).where("google_accounts.youtube_data_api_key IS NOT NULL AND google_accounts.youtube_data_api_key <> '' AND ip_addresses.address_target = ?", IpAddress.address_target.find_value("free_proxy").value).order("random()").first
        p_addr = random_system_account.ip_address.address
        p_port = random_system_account.ip_address.port
        api_key = random_system_account.email_item.youtube_data_api_key
        YoutubeService.grab_video_statistics(@youtube_video, p_addr, p_port, api_key, true)
      end
			@youtube_video.is_active = params[:is_active] if params[:is_active].present?
			@youtube_video.linked = params[:linked] if params[:linked].present?
      @youtube_video.deleted = params[:deleted] if params[:deleted].present?
      @youtube_video.ready = params[:ready] if params[:ready].present?
      if params[:save_publication_date].present? && params[:save_publication_date] == 'true'
        @youtube_video.publication_date = Time.now
        YoutubeService.delay(queue: DelayedJobQueue::GRAB_YOUTUBE_STATISTICS, priority: 0, run_at: 1.hour.from_now).grab_video_statistics(@youtube_video, nil, nil, nil, true) if Setting.get_value_by_name("YoutubeService::YOUTUBE_STATISTICS_ENABLED") == "true"
      end
			@youtube_video.delay(queue: DelayedJobQueue::SAVE_SCREENSHOT, priority: 1).save_screenshot if params[:save_screenshot].present? && params[:save_screenshot] == 'true'
      @youtube_video.fields_to_update = "" if params[:clear_fields_to_update].present? && params[:clear_fields_to_update] == 'true'
      if params[:posted_on_google_plus] == 'true'
        @youtube_video.posted_on_google_plus = true
        @youtube_video.posted_on_google_plus_at = Time.now
      end
			@youtube_video.save
      @youtube_video.add_posting_time if params[:save_publication_date].present? && params[:save_publication_date] == 'true'
      @youtube_video.add_google_plus_upload_time if params[:posted_on_google_plus].present? && params[:posted_on_google_plus] == 'true'
      Utils.delay(queue: DelayedJobQueue::OTHER, priority: DelayedJobPriority::HIGH).save_web_screenshot(@youtube_video, @youtube_video.url) if @youtube_video.url.present?
			{ status: 200 }
		else
			{ status: 500 }
		end

		render json: response, status: response[:status]
	end

  def regenerate_video_thumbnail
    if @youtube_video.blended_video.present?
      tmp_youtube_video_thumbnail_path = File.join('/tmp',"regenerate-youtube-video-thumb-#{SecureRandom.uuid}.jpg")
      Templates::Images::VideoThumbnailGenerator.random_youtube_video_thumbnail(@youtube_video.id).write(tmp_youtube_video_thumbnail_path)
			f = File.open(tmp_youtube_video_thumbnail_path, 'r')
			@youtube_video.thumbnail = f
      @youtube_video.save!
			f.close
      FileUtils.rm_rf tmp_youtube_video_thumbnail_path
    end
    respond_to do |format|
      format.html { redirect_to :back, notice: "Thumbnail was successfully regenerated" }
      format.json { head :no_content }
    end
  end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_youtube_video
			@youtube_video = YoutubeVideo.find(params[:id])
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def youtube_video_params
			params[:youtube_video][:youtube_video_id] = nil if params[:youtube_video] && params[:youtube_video][:youtube_video_id].try(:strip).blank?
			params.require(:youtube_video).permit!
		end
end
