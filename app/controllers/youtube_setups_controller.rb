class YoutubeSetupsController < ApplicationController
	include YoutubeSetupsHelper

	before_action :set_youtube_setup, only: [:show, :edit, :update, :destroy, :assign_accounts, :regenerate_channels_content, :generate_test_titles]

	def index
		@youtube_setups = if params[:client_id].present?
			@client = Client.find(params[:client_id].to_i)
			YoutubeSetup.where('client_id = ?', params[:client_id].to_i)
		else
			YoutubeSetup.all
		end
	end

	def show
	end

	def new
		@youtube_setup = if params[:client_id].present? || params[:youtube_setup][:client_id]
			client_id = params[:client_id] || params[:youtube_setup][:client_id]
			@client = Client.find(client_id.to_i)
      industry = @client.industry
			email_accounts_setup_id = params[:email_accounts_setup_id].present? ? params[:email_accounts_setup_id].to_i : nil
      donor_client_id = nil
      if email_accounts_setup_id.present?
        donor_product_ids = EmailAccountsSetup.find(email_accounts_setup_id).contract.products.map(&:parent_id).compact
        if donor_product_ids.present?
          donor_client_id = Product.where(id: donor_product_ids).first.try(:client_id)
        end
      end
      donor_client_id = donor_client_id || @client.donors.last.try(:id)
      source_youtube_setup = donor_client_id.present? && YoutubeSetup.where(client_id: donor_client_id).last.present? ? YoutubeSetup.where(client_id: donor_client_id).last : YoutubeSetup.new(business_channel_descriptor: industry.business_channel_descriptor, business_channel_entity: industry.business_channel_entity, business_channel_subject: industry.business_channel_subject, business_video_descriptor: industry.business_video_descriptor, business_video_entity: industry.business_video_entity, business_video_subject: industry.business_video_subject, business_channel_title_patterns: industry.business_channel_title_patterns, business_video_title_patterns: industry.business_video_title_patterns)
      youtube_setup = YoutubeSetup.new(source_youtube_setup.attributes)
      youtube_setup.attributes = {client_id: client_id.to_i, email_accounts_setup_id: email_accounts_setup_id, use_youtube_channel_art: true, adwords_campaign_networks_youtube_search: true, adwords_campaign_networks_youtube_videos: true, adwords_campaign_networks_include_video_partners: true, adwords_campaign_type: YoutubeSetup.adwords_campaign_type.find_value('Video'), adwords_campaign_group_video_ad_format: YoutubeSetup.adwords_campaign_group_video_ad_format.find_value('In-display ad'), call_to_action_overlay_enabled_on_mobile: true, business_channel_title_components_shuffle: true, business_video_title_components_shuffle: true, use_youtube_video_cards: true, use_youtube_video_thumbnail: true, use_call_to_action_overlays: false, rotate_content_frequency: 180, updated_at: nil, created_at: nil, id: nil}
      %w(business_channel_descriptor business_channel_entity business_channel_subject business_video_descriptor business_video_entity business_video_subject business_channel_title_patterns business_video_title_patterns).each do |field|
        youtube_setup[:"#{field}"] = industry[:"#{field}"] unless youtube_setup[:"#{field}"].present?
      end
      youtube_setup
		else
			YoutubeSetup.new(business_channel_title_patterns: [YoutubeComponentPattern.where(component_type: YoutubeComponentPattern.component_type.find_value('channel_title').value, components: 'B,D,F').first.try(:components)].compact, business_video_title_patterns: [YoutubeComponentPattern.where(component_type: YoutubeComponentPattern.component_type.find_value('video_title').value, components: 'G,B,C,E,F').first.try(:components)].compact, business_channel_title_components_shuffle: true, business_video_title_components_shuffle: true, use_youtube_video_cards: true, use_youtube_video_thumbnail: true, use_call_to_action_overlays: false, rotate_content_frequency: 180)
		end
		@youtube_setup
	end

	def edit
		@client = @youtube_setup.client
	end

	def create
		@youtube_setup = YoutubeSetup.new(youtube_setup_params)

		respond_to do |format|
			if @youtube_setup.save
				format.html { redirect_to client_youtube_setups_path(client_id: @youtube_setup.client.id), notice: 'Youtube setup was successfully created.' }
				format.json { render action: 'show', status: :created, location: @youtube_setup }
			else
				@client = Client.find(@youtube_setup.client_id)
				format.html { render action: 'new' }
				format.json { render json: @youtube_setup.errors, status: :unprocessable_entity }
			end
		end
	end

	def update
    ap youtube_setup_params
		respond_to do |format|
			if @youtube_setup.update(youtube_setup_params)
				format.html { redirect_to client_youtube_setups_path(client_id: @youtube_setup.client_id), notice: 'Youtube setup was successfully updated.' }
				format.json { head :no_content }
			else
				@client = @youtube_setup.client
				format.html { render action: 'edit' }
				format.json { render json: @youtube_setup.errors, status: :unprocessable_entity }
			end
		end
	end

	def destroy
		@youtube_setup.destroy
		respond_to do |format|
			format.html { redirect_to client_youtube_setups_path(client_id: @youtube_setup.client_id) }
			format.json { head :no_content }
		end
	end

	def assign_accounts
		message, alert = nil

		if @youtube_setup.nil? || @youtube_setup.email_accounts_setup.approved || @youtube_setup.client.nil?
			alert = if @youtube_setup.nil?
				"Can't find youtube setup with id=#{params[:youtube_setup_id]}"
			elsif @youtube_setup.client.nil?
				'This youtube setup is not assigned to client'
			else
				'Assign accounts action for this email account setup was already done'
			end
		else
			email_accounts_setup = @youtube_setup.email_accounts_setup
			# Add in query accounts with personal channel but without business
      active_accounts_pool = []
      google_accounts = GoogleAccount.joins("LEFT JOIN google_account_activities ON google_account_activities.google_account_id = google_accounts.id LEFT JOIN youtube_channels ON youtube_channels.google_account_id = google_accounts.id LEFT JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id AND email_accounts.email_item_type = 'GoogleAccount'").where("email_accounts.created_at > '2015-02-07 00:00:00' AND email_accounts.client_id IS NULL AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value} AND email_accounts.is_active = TRUE AND email_accounts.recovery_phone_assigned IS NOT FALSE AND email_accounts.deleted IS NOT TRUE AND youtube_channels.id IS NOT NULL AND youtube_channels.channel_type = ? AND youtube_channels.is_active = TRUE AND array_length(google_account_activities.youtube_business_channel, 1) IS NULL", YoutubeChannel.channel_type.find_value(:personal).value).order('email_accounts.recovery_phone_assigned desc NULLS LAST, google_account_activities.recovery_email DESC NULLS LAST, email_accounts.created_at asc')
      google_accounts.each { | ga | active_accounts_pool << ga.email_account if ga.youtube_channels.size == 1 && !RecoveryInboxEmail.where("email_account_id = ? AND date > ? AND email_type in (?)", ga.email_account.id, Time.now - 14.days, [RecoveryInboxEmail.email_type.find_value("Action required: Your Google Account is temporarily disabled").value, RecoveryInboxEmail.email_type.find_value("Google Account has been disabled").value, RecoveryInboxEmail.email_type.find_value("Google Account has been disabled (FR)").value, RecoveryInboxEmail.email_type.find_value("Google Account disabled").value]).present?}

			puts "Accounts pool size: #{active_accounts_pool.size}"

			accounts_number = email_accounts_setup.accounts_number - email_accounts_setup.email_accounts.size

			if active_accounts_pool.size >= accounts_number
				client_id = @youtube_setup.client_id
				accounts = active_accounts_pool.first(accounts_number)
        bot_server = BotServer.where(path: Setting.get_value_by_name("EmailAccount::BOT_URL")).first
				accounts.each do |acc|
					acc.client_id = client_id
					acc.email_accounts_setup_id = email_accounts_setup.id
          #assign to bot server
          acc.bot_server_id = bot_server.try(:id)
				end

				if email_accounts_setup.cities.present?
					localities_ids = email_accounts_setup.cities.map(&:to_i) - email_accounts_setup.email_accounts.map(&:locality_id).compact
					localities = Geobase::Locality.where('id in (?)', localities_ids).order(population: :desc)
					# assign

					if localities.size >= accounts_number
						localities.each_with_index do |locality, index|
							account = accounts[index]
							if account.present?
								account.locality_id = locality.id
								account.save
							end
						end
					else
						accounts.each_with_index do |account, index|
							locality = localities[index%localities.size]
							account.locality_id = locality.id
							account.save
						end
					end
				else
					regions_ids = email_accounts_setup.counties.present? ? email_accounts_setup.counties.map(&:to_i) : email_accounts_setup.states.map(&:to_i)
					regions_ids = regions_ids - email_accounts_setup.email_accounts.map(&:region_id).compact
					regions = Geobase::Region.where('id in (?)', regions_ids).order(:name)
					# assign
					if regions.size >= accounts_number
						regions.each_with_index do |region, index|
							account = accounts[index]
							if account.present?
								account.region_id = region.id
								account.save
							end
						end
					else
						accounts.each_with_index do |account, index|
							region = regions[index%regions.size]
							account.region_id = region.id
							account.save
						end
					end
				end
				email_accounts_setup.approved = true
				email_accounts_setup.save
				message = 'Assign accounts successfully executed. Job for creating channels is added to queue. See statistics on dashboard.'
				# Run here delay job for creating youtube channels
				YoutubeService.delay(queue: DelayedJobQueue::START_CHANNELS_PROCESS, priority: 0).start_channels_process(email_accounts_setup.id)
			else
				# Return message that you have no enough accounts
				alert = "You have no enough accounts in the pool. Current pool size: #{active_accounts_pool.size}, but you need #{accounts_number}. On this page, you can order new accounts. When new accounts will be created, press button 'Start process' again."
        redirect_to order_email_accounts_path, notice: message, alert: alert
        return
			end
		end
		redirect_to client_youtube_setups_path(client_id: @youtube_setup.client_id), notice: message, alert: alert
	end

	def regenerate_channels_content
		message, alert = nil
		youtube_channels = YoutubeChannel.includes(google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}])
		.by_linked(true.to_s)
		.by_channel_type(YoutubeChannel::CHANNEL_TYPES[:business])
		.by_client_id(@youtube_setup.client_id)
		.where("email_accounts.email_accounts_setup_id = ?", @youtube_setup.email_accounts_setup_id)
		.references(google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}])
		youtube_channels.each do |business_channel|
			YoutubeService.regenerate_youtube_business_channel_content(business_channel, true, exclude_fields_list = ['channel_art', 'channel_icon', 'business_inquiries_email'])
		end
		message = youtube_channels.size.to_s
		redirect_to client_youtube_setups_path(client_id: @youtube_setup.client_id), notice: message, alert: alert
	end

  def generate_test_titles
    @titles = []
    20.times do
      @titles << YoutubeService.generate_youtube_video_title(nil, @youtube_setup)
    end
    #render :generate_test_title, locals: {titles: titles.compact.reject(&:blank?).uniq}
    @titles = @titles.compact.reject(&:blank?).uniq
  end

  def tags_overview
    render :tags_overview, locals: {email_accounts_setup: EmailAccountsSetup.find(params[:email_accounts_setup_id]), target: params[:target]}
  end

  def descriptions_overview
    render :descriptions_overview, locals: {email_accounts_setup: EmailAccountsSetup.find(params[:email_accounts_setup_id]), target: params[:target]}
  end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_youtube_setup
			@youtube_setup = YoutubeSetup.find(params[:id])
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def youtube_setup_params
			# Temporary, need to fix
			%w(adwords_campaign_start_date adwords_campaign_end_date).each do |field|
				params[:youtube_setup][field] = Date.strptime(params[:youtube_setup][field], '%m/%d/%Y') if params[:youtube_setup][field].present? && (params[:youtube_setup][field].is_a? String)
			end
      %w(channel video).each do |type|
        params[:youtube_setup][:"business_#{type}_title_patterns"] = [] if (params[:youtube_setup][:"business_#{type}_title_patterns"].is_a? Array) && !params[:youtube_setup][:"business_#{type}_title_patterns"].reject(&:empty?).present?
        params[:youtube_setup][:"business_#{type}_title_patterns"] = params[:youtube_setup][:"business_#{type}_title_patterns"].reject(&:empty?) if (params[:youtube_setup][:"business_#{type}_title_patterns"].is_a? Array) && params[:youtube_setup][:"business_#{type}_title_patterns"].reject(&:empty?).present?
      end
			params[:youtube_setup][:adwords_campaign_languages] = params[:youtube_setup][:adwords_campaign_languages].reject { |c| c.empty? } if params[:youtube_setup][:adwords_campaign_languages].present?
			params[:youtube_setup][:adwords_campaign_languages] = params[:youtube_setup][:adwords_campaign_languages].join(',') if (params[:youtube_setup][:adwords_campaign_languages].is_a? Array)
			params[:youtube_setup][:youtube_video_annotation_templates_attributes] = JSON.parse(params[:youtube_setup][:youtube_video_annotation_templates_attributes].to_s)
			params[:youtube_setup][:youtube_video_card_templates_attributes] = JSON.parse(params[:youtube_setup][:youtube_video_card_templates_attributes].to_s)
			params.require(:youtube_setup).permit!
		end
end
