class DashboardController < ApplicationController
	skip_before_filter :authenticate_admin_user!, :only => [:server_stat_json]

	def bot_statistics_json
		response = "{}"
		if params[:bot_server_id].present?
			bot_server = BotServer.find(params[:bot_server_id].to_i)
			threads_data = (bot_server.active_threads_data.present? && params[:thread].present? && params[:thread] == "active" && bot_server.active_threads_updated_at > Time.now - 2.minute) ? bot_server.active_threads_data : nil
			empty_data = {'cpu_usage'=>'','ram_usage'=>'','ram'=>'','maximum_threads'=>'','active_threads'=>'','queue'=>'','queue_crashed'=>'','time_on_server'=>'','container-uptime'=>'','hdd_free_space'=>'','hdd_total_space'=>''}
			response = threads_data.present? ? threads_data.to_s : empty_data.to_json
		end
		render json: response
	end

	def server_hardware_json
		response = "{}"
		if params[:bot_server_id].present?
			bot_server = BotServer.find(params[:bot_server_id].to_i)
			response = (bot_server.hardware_data_updated_at.present? && bot_server.hardware_data_updated_at > Time.now - 2.minute) ? bot_server.hardware_data_json(params[:system_load_period].to_i).to_s : bot_server.hardware_data_json(params[:system_load_period].to_i, "{}").to_s
		end
		render json: response
	end

	# temporary solution
	def server_stat_json
		ip = params[:ip]
		last = if ip.present?
			url = "http://#{ip}/hw-stat.php"
			json = %x(curl -X GET "#{url}")
			js = JSON.parse(json)
			js.first.to_json
		else
			""
		end
		render json: last
	end

	def index
		send("#{current_admin_user.roles}_index")
	end

	def video_workflow
		render json: {
			delayed_jobs: JSON.parse(ActiveRecord::Base.connection.select_value('SELECT dashboard_video_workflow_get_dj_statistics_json()')  || "{}"),
			undone_items: JSON.parse(ActiveRecord::Base.connection.select_value('SELECT dashboard_video_workflow_get_undone_items_json()') || "{}")
		}.to_json
	end

  def send_yt_stat_report
    YoutubeService.send_yt_stat_report
    render json: {status: 200}
  end

	private
		def admin_index
			respond_to do |format|
				@did_phone_provider_id = PhoneProvider.find_by_name('voip-ms').try(:id) || PhoneProvider.create(name: "voip-ms").id
				format.html {
          params[:video_workflow_period] = 24 unless params[:video_workflow_period].present?
          params[:youtube_channels_period] = 24 unless params[:youtube_channels_period].present?
          params[:youtube_videos_period] = 24 unless params[:youtube_videos_period].present?
          params[:email_accounts_period] = 24 unless params[:email_accounts_period].present?
          params[:recovery_inbox_emails_period] = 24 unless params[:recovery_inbox_emails_period].present?
          params[:recovery_attempt_answers_period] = 24 unless params[:recovery_attempt_answers_period].present?
          params[:crawler_statuses_period] = 24.0 unless params[:crawler_statuses_period].present?
        }
				format.json {
          json_text = {}
          problems = []
          bot_server = BotServer.find(params[:bot_server_id].to_i)
          youtube_channels_bot_server = params[:youtube_channels_bot_server_id].present? ? BotServer.find_by_id(params[:youtube_channels_bot_server_id].to_i) : nil
          youtube_videos_bot_server = params[:youtube_videos_bot_server_id].present? ? BotServer.find_by_id(params[:youtube_videos_bot_server_id].to_i) : nil
          operational_type = EmailAccount.account_type.find_value(:operational).value
          phone_usages_period = params[:phone_usages_period].present? ? params[:phone_usages_period].to_i : 1
          video_workflow_period = params[:video_workflow_period].present? ? params[:video_workflow_period].to_i : 24
          youtube_channels_period = params[:youtube_channels_period].present? ? params[:youtube_channels_period].to_i : 24
          youtube_videos_period = params[:youtube_videos_period].present? ? params[:youtube_videos_period].to_i : 24
          email_accounts_period = params[:email_accounts_period].present? ? params[:email_accounts_period].to_i : 24
          recovery_inbox_emails_period = params[:recovery_inbox_emails_period].present? ? params[:recovery_inbox_emails_period].to_i : 24
          recovery_attempt_answers_period = params[:recovery_attempt_answers_period].present? ? params[:recovery_attempt_answers_period].to_i : 24
          crawler_statuses_period = params[:crawler_statuses_period].present? ? params[:crawler_statuses_period].to_f : 24.0
          youtube_channels_period = nil if youtube_channels_period == 0
          youtube_videos_period = nil if youtube_videos_period == 0
          crawler_statuses_period = nil if crawler_statuses_period == 0
          youtube_channels_client = params[:youtube_channels_client_id].present? ? Client.find_by_id(params[:youtube_channels_client_id].to_i) : nil
          youtube_videos_client = params[:youtube_videos_client_id].present? ? Client.find_by_id(params[:youtube_videos_client_id].to_i) : nil
					active_email_accounts_size = EmailAccount.includes({locality: [{primary_region: [:country]}]}, :client, :region).joins('LEFT OUTER JOIN google_accounts ON email_accounts.email_item_id = google_accounts.id LEFT OUTER JOIN google_account_activities ON google_accounts.id = google_account_activities.google_account_id').by_display_all(nil).by_account_type(operational_type).by_is_active(true.to_s).size
					inactive_email_accounts_size = EmailAccount.includes({locality: [{primary_region: [:country]}]}, :client, :region).joins('LEFT OUTER JOIN google_accounts ON email_accounts.email_item_id = google_accounts.id LEFT OUTER JOIN google_account_activities ON google_accounts.id = google_account_activities.google_account_id').by_display_all(nil).by_account_type(operational_type).by_is_active(false.to_s).by_deleted(false.to_s).size
          recovery_email_sync_size = EmailAccount.joins('LEFT OUTER JOIN google_accounts ON email_accounts.email_item_id = google_accounts.id LEFT OUTER JOIN google_account_activities ON google_accounts.id = google_account_activities.google_account_id').by_display_all(nil).by_account_type(operational_type).by_is_active(true.to_s).by_recovery_email_sync(true.to_s).size
          not_recovery_email_sync_size = EmailAccount.joins('LEFT OUTER JOIN google_accounts ON email_accounts.email_item_id = google_accounts.id LEFT OUTER JOIN google_account_activities ON google_accounts.id = google_account_activities.google_account_id').by_display_all(nil).by_account_type(operational_type).by_is_active(true.to_s).by_recovery_email_sync(false.to_s).size
          active_accounts_recovery_inbox_emails_size = EmailAccount.unscoped.distinct.joins('LEFT OUTER JOIN google_accounts ON email_accounts.email_item_id = google_accounts.id LEFT OUTER JOIN google_account_activities ON google_accounts.id = google_account_activities.google_account_id LEFT OUTER JOIN recovery_inbox_emails ON recovery_inbox_emails.email_account_id = email_accounts.id').by_display_all(nil).by_is_active(true.to_s).by_account_type(operational_type).by_last_event_time("recovery_inbox_emails", "date", email_accounts_period).size
          active_accounts_recovery_inbox_emails_url = email_accounts_path(account_type: operational_type, is_active: true, recovery_inbox_email_last_time: email_accounts_period)
          inactive_accounts_recovery_inbox_emails_size = EmailAccount.unscoped.distinct.joins('LEFT OUTER JOIN google_accounts ON email_accounts.email_item_id = google_accounts.id LEFT OUTER JOIN google_account_activities ON google_accounts.id = google_account_activities.google_account_id LEFT OUTER JOIN recovery_inbox_emails ON recovery_inbox_emails.email_account_id = email_accounts.id').by_display_all(nil).by_is_active(false.to_s).by_account_type(operational_type).by_last_event_time("recovery_inbox_emails", "date", email_accounts_period).size
          inactive_accounts_recovery_inbox_emails_url = email_accounts_path(account_type: operational_type, is_active: false, recovery_inbox_email_last_time: email_accounts_period)
          active_accounts_status_changed_size = EmailAccount.unscoped.distinct.joins('LEFT OUTER JOIN google_accounts ON email_accounts.email_item_id = google_accounts.id LEFT OUTER JOIN google_account_activities ON google_accounts.id = google_account_activities.google_account_id').by_display_all(nil).by_is_active(true.to_s).by_account_type(operational_type).by_last_event_time("email_accounts", "status_change_date", email_accounts_period).size
          active_accounts_status_changed_url = email_accounts_path(account_type: operational_type, is_active: true, status_changed_last_time: email_accounts_period)
          inactive_accounts_status_changed_size = EmailAccount.unscoped.distinct.joins('LEFT OUTER JOIN google_accounts ON email_accounts.email_item_id = google_accounts.id LEFT OUTER JOIN google_account_activities ON google_accounts.id = google_account_activities.google_account_id').by_display_all(nil).by_is_active(false.to_s).by_account_type(operational_type).by_last_event_time("email_accounts", "status_change_date", email_accounts_period).size
          inactive_accounts_status_changed_url = email_accounts_path(account_type: operational_type, is_active: false, status_changed_last_time: email_accounts_period)
					deleted_email_accounts_size = EmailAccount.includes({locality: [{primary_region: [:country]}]}, :client, :region).joins('LEFT OUTER JOIN google_accounts ON email_accounts.email_item_id = google_accounts.id LEFT OUTER JOIN google_account_activities ON google_accounts.id = google_account_activities.google_account_id').by_display_all(nil).by_account_type(operational_type).by_lost(false.to_s).size
					lost_email_accounts_size = EmailAccount.includes({locality: [{primary_region: [:country]}]}, :client, :region).joins('LEFT OUTER JOIN google_accounts ON email_accounts.email_item_id = google_accounts.id LEFT OUTER JOIN google_account_activities ON google_accounts.id = google_account_activities.google_account_id').by_display_all(nil).by_account_type(operational_type).by_lost(true.to_s).size
					with_recovery_phone_assigned_size = EmailAccount.includes({locality: [{primary_region: [:country]}]}, :client, :region).joins('LEFT OUTER JOIN google_accounts ON email_accounts.email_item_id = google_accounts.id LEFT OUTER JOIN google_account_activities ON google_accounts.id = google_account_activities.google_account_id').by_display_all(nil).by_account_type(operational_type).by_recovery_phone_assigned(true.to_s).by_is_active(true.to_s).size
					waiting_recovery_phone_assigned_size = EmailAccount.includes({locality: [{primary_region: [:country]}]}, :client, :region).joins('LEFT OUTER JOIN google_accounts ON email_accounts.email_item_id = google_accounts.id LEFT OUTER JOIN google_account_activities ON google_accounts.id = google_account_activities.google_account_id').by_display_all(nil).by_account_type(operational_type).by_recovery_phone_assigned(false.to_s).by_is_active(true.to_s).size
					without_recovery_phone_assigned_size = EmailAccount.includes({locality: [{primary_region: [:country]}]}, :client, :region).joins('LEFT OUTER JOIN google_accounts ON email_accounts.email_item_id = google_accounts.id LEFT OUTER JOIN google_account_activities ON google_accounts.id = google_account_activities.google_account_id').by_display_all(nil).by_account_type(operational_type).by_recovery_phone_assigned('no').by_is_active(true.to_s).size
					suspended_recovery_phone_assigned_size = EmailAccount.includes({locality: [{primary_region: [:country]}]}, :client, :region).joins('LEFT OUTER JOIN google_accounts ON email_accounts.email_item_id = google_accounts.id LEFT OUTER JOIN google_account_activities ON google_accounts.id = google_account_activities.google_account_id').by_display_all(nil).by_account_type(operational_type).by_is_active(true.to_s).by_recovery_phone_assigned('suspended').size
					has_alternate_email_size = EmailAccount.includes({locality: [{primary_region: [:country]}]}, :client, :region).joins('LEFT OUTER JOIN google_accounts ON email_accounts.email_item_id = google_accounts.id LEFT OUTER JOIN google_account_activities ON google_accounts.id = google_account_activities.google_account_id').by_display_all(nil).by_account_type(operational_type).by_is_active(true.to_s).by_has_alternate_email(true.to_s).size
					has_no_alternate_email_size = EmailAccount.includes({locality: [{primary_region: [:country]}]}, :client, :region).joins('LEFT OUTER JOIN google_accounts ON email_accounts.email_item_id = google_accounts.id LEFT OUTER JOIN google_account_activities ON google_accounts.id = google_account_activities.google_account_id').by_display_all(nil).by_account_type(operational_type).by_is_active(true.to_s).by_has_alternate_email(false.to_s).size
					has_recovery_email_size = EmailAccount.includes({locality: [{primary_region: [:country]}]}, :client, :region).joins('LEFT OUTER JOIN google_accounts ON email_accounts.email_item_id = google_accounts.id LEFT OUTER JOIN google_account_activities ON google_accounts.id = google_account_activities.google_account_id').by_display_all(nil).by_account_type(operational_type).by_is_active(true.to_s).by_has_recovery_email(true.to_s).size
					has_no_recovery_email_size = EmailAccount.includes({locality: [{primary_region: [:country]}]}, :client, :region).joins('LEFT OUTER JOIN google_accounts ON email_accounts.email_item_id = google_accounts.id LEFT OUTER JOIN google_account_activities ON google_accounts.id = google_account_activities.google_account_id').by_display_all(nil).by_account_type(operational_type).by_is_active(true.to_s).by_has_recovery_email(false.to_s).size
          assigned_to_client_accounts_size = EmailAccount.includes({locality: [{primary_region: [:country]}]}, :client, :region).joins('LEFT OUTER JOIN google_accounts ON email_accounts.email_item_id = google_accounts.id LEFT OUTER JOIN google_account_activities ON google_accounts.id = google_account_activities.google_account_id').by_display_all(nil).by_account_type(operational_type).by_is_active(true.to_s).by_assigned_to_client(true.to_s).size
          not_assigned_to_client_accounts_size = EmailAccount.includes({locality: [{primary_region: [:country]}]}, :client, :region).joins('LEFT OUTER JOIN google_accounts ON email_accounts.email_item_id = google_accounts.id LEFT OUTER JOIN google_account_activities ON google_accounts.id = google_account_activities.google_account_id').by_display_all(nil).by_account_type(operational_type).by_is_active(true.to_s).by_assigned_to_client(false.to_s).size

					active_accounts_pool = []
		      active_google_accounts_pool = GoogleAccount.joins("LEFT JOIN google_account_activities ON google_account_activities.google_account_id = google_accounts.id LEFT JOIN youtube_channels ON youtube_channels.google_account_id = google_accounts.id LEFT JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id AND email_accounts.email_item_type = 'GoogleAccount'").where("email_accounts.created_at > '2015-02-07 00:00:00' AND email_accounts.client_id IS NULL AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value} AND email_accounts.is_active = TRUE AND email_accounts.recovery_phone_assigned IS NOT FALSE AND email_accounts.deleted IS NOT TRUE AND youtube_channels.id IS NOT NULL AND youtube_channels.channel_type = ? AND youtube_channels.is_active = TRUE AND array_length(google_account_activities.youtube_business_channel, 1) IS NULL", YoutubeChannel.channel_type.find_value(:personal).value).order('email_accounts.recovery_phone_assigned desc NULLS LAST, google_account_activities.recovery_email DESC NULLS LAST, email_accounts.created_at asc')
		      active_google_accounts_pool.each { | ga | active_accounts_pool << ga.email_account if ga.youtube_channels.size == 1 && !RecoveryInboxEmail.where("email_account_id = ? AND date > ? AND email_type in (?)", ga.email_account.id, Time.now - 14.days, [RecoveryInboxEmail.email_type.find_value("Action required: Your Google Account is temporarily disabled").value, RecoveryInboxEmail.email_type.find_value("Google Account has been disabled").value, RecoveryInboxEmail.email_type.find_value("Google Account has been disabled (FR)").value, RecoveryInboxEmail.email_type.find_value("Google Account disabled").value]).present?}
					active_accounts_pool_ids = active_accounts_pool.map(&:id)
					active_accounts_pool_size = active_accounts_pool_ids.size
					active_accounts_pool_url = active_accounts_pool_ids.present? ? email_accounts_path(id: active_accounts_pool_ids.join(",")) : "javascript://"

          #channels
          #total channels
          channels_size = YoutubeChannel.distinct.includes(google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]).by_display_all(nil).by_channel_type(YoutubeChannel.channel_type.find_value(:business).value.to_s).references(google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]).size
          channels_url = youtube_channels_path(channel_type: YoutubeChannel.channel_type.find_value(:business).value.to_s)
          total_published_business_channels_size = YoutubeChannel.distinct.includes(google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]).by_display_all(nil).by_channel_type(YoutubeChannel.channel_type.find_value(:business).value.to_s).by_is_active(true.to_s).by_linked(true.to_s).references(google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]).size
          total_published_business_channels_url = youtube_channels_path(channel_type: YoutubeChannel.channel_type.find_value(:business).value.to_s, is_active: true, linked: true)
          total_not_published_business_channels_size = YoutubeChannel.distinct.includes(google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]).by_display_all(nil).by_channel_type(YoutubeChannel.channel_type.find_value(:business).value.to_s).by_linked(false.to_s).by_is_active(false.to_s).by_ready(true.to_s).references(google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]).size
          total_not_published_business_channels_url = youtube_channels_path(channel_type: YoutubeChannel.channel_type.find_value(:business).value.to_s, is_active: false, linked: false, ready: true)
          total_blocked_business_channels_size = YoutubeChannel.distinct.includes(google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]).by_display_all(nil).by_channel_type(YoutubeChannel.channel_type.find_value(:business).value.to_s).by_blocked(true.to_s).references(google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]).size
          total_blocked_business_channels_url = youtube_channels_path(channel_type: YoutubeChannel.channel_type.find_value(:business).value.to_s, blocked: true)
          total_pending_approval_business_channels_size = YoutubeChannel.distinct.includes(google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]).by_display_all(nil).by_channel_type(YoutubeChannel.channel_type.find_value(:business).value.to_s).by_ready(false.to_s).references(google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]).size
          total_pending_approval_business_channels_url = youtube_channels_path(channel_type: YoutubeChannel.channel_type.find_value(:business).value.to_s, ready: false)

					published_business_channels_size = YoutubeChannel.distinct.includes(google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]).by_display_all(nil).by_bot_server_id(youtube_channels_bot_server.try(:id)).by_client_id(youtube_channels_client.try(:id)).by_channel_type(YoutubeChannel.channel_type.find_value(:business).value.to_s).by_is_active(true.to_s).by_linked(true.to_s).by_last_event_time('youtube_channels', 'publication_date', youtube_channels_period).references(google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]).size
          published_business_channels_url = youtube_channels_path(channel_type: YoutubeChannel.channel_type.find_value(:business).value.to_s, is_active: true, linked: true, table_name: 'youtube_channels', field_name: 'publication_date', last_time: youtube_channels_period, bot_server_id: youtube_channels_bot_server.try(:id), client_id: youtube_channels_client.try(:id))
          not_published_business_channels_size = YoutubeChannel.distinct.includes(google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]).by_display_all(nil).by_bot_server_id(youtube_channels_bot_server.try(:id)).by_client_id(youtube_channels_client.try(:id)).by_channel_type(YoutubeChannel.channel_type.find_value(:business).value.to_s).by_linked(false.to_s).by_is_active(false.to_s).by_ready(true.to_s).by_last_event_time('youtube_channels', 'updated_at', youtube_channels_period).references(google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]).size
          not_published_business_channels_url = youtube_channels_path(channel_type: YoutubeChannel.channel_type.find_value(:business).value.to_s, is_active: false, linked: false, ready: true, table_name: 'youtube_channels', field_name: 'updated_at', last_time: youtube_channels_period, bot_server_id: youtube_channels_bot_server.try(:id), client_id: youtube_channels_client.try(:id))
          blocked_business_channels_size = YoutubeChannel.distinct.includes(google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]).by_display_all(nil).by_bot_server_id(youtube_channels_bot_server.try(:id)).by_client_id(youtube_channels_client.try(:id)).by_channel_type(YoutubeChannel.channel_type.find_value(:business).value.to_s).by_blocked(true.to_s).by_last_event_time('youtube_channels', 'updated_at', youtube_channels_period).references(google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]).size
          blocked_business_channels_url = youtube_channels_path(channel_type: YoutubeChannel.channel_type.find_value(:business).value.to_s, blocked: true, table_name: 'youtube_channels', field_name: 'updated_at', last_time: youtube_channels_period, bot_server_id: youtube_channels_bot_server.try(:id), client_id: youtube_channels_client.try(:id))
          created_by_phone_business_channels_size = YoutubeChannel.includes(google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]).joins("LEFT JOIN phone_usages ON youtube_channels.id = phone_usages.phone_usageable_id AND phone_usages.phone_usageable_type = 'YoutubeChannel'").by_display_all(nil).by_bot_server_id(youtube_channels_bot_server.try(:id)).by_client_id(youtube_channels_client.try(:id)).by_channel_type(YoutubeChannel.channel_type.find_value(:business).value.to_s).by_created_by_phone(true.to_s).by_last_event_time('youtube_channels', 'publication_date', youtube_channels_period).references(google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]).size
          not_created_by_phone_business_channels_size = published_business_channels_size - created_by_phone_business_channels_size
          created_by_phone_business_channels_url = youtube_channels_path(channel_type: YoutubeChannel.channel_type.find_value(:business).value.to_s, created_by_phone: true, table_name: 'youtube_channels', field_name: 'publication_date', last_time: youtube_channels_period, bot_server_id: youtube_channels_bot_server.try(:id), client_id: youtube_channels_client.try(:id))
					phone_verified_business_channels_size = YoutubeChannel.includes(google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]).by_display_all(nil).by_bot_server_id(youtube_channels_bot_server.try(:id)).by_client_id(youtube_channels_client.try(:id)).by_channel_type(YoutubeChannel.channel_type.find_value(:business).value.to_s).by_is_verified_by_phone(true.to_s).by_last_event_time('youtube_channels', 'updated_at', youtube_channels_period).references(google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]).size
          phone_verified_business_channels_url = youtube_channels_path(channel_type: YoutubeChannel.channel_type.find_value(:business).value.to_s, is_verified_by_phone: true, table_name: 'youtube_channels', field_name: 'updated_at', last_time: youtube_channels_period, bot_server_id: youtube_channels_bot_server.try(:id), client_id: youtube_channels_client.try(:id))
          phone_unverified_business_channels_size = YoutubeChannel.distinct.includes(google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]).by_display_all(nil).by_bot_server_id(youtube_channels_bot_server.try(:id)).by_client_id(youtube_channels_client.try(:id)).by_channel_type(YoutubeChannel.channel_type.find_value(:business).value.to_s).by_is_verified_by_phone(false.to_s).by_last_event_time('youtube_channels', 'updated_at', youtube_channels_period).references(google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]).size
          phone_unverified_business_channels_url = youtube_channels_path(channel_type: YoutubeChannel.channel_type.find_value(:business).value.to_s, is_verified_by_phone: false, table_name: 'youtube_channels', field_name: 'updated_at', last_time: youtube_channels_period, bot_server_id: youtube_channels_bot_server.try(:id), client_id: youtube_channels_client.try(:id))
					filled_business_channels_size = YoutubeChannel.distinct.includes(google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]).by_display_all(nil).by_bot_server_id(youtube_channels_bot_server.try(:id)).by_client_id(youtube_channels_client.try(:id)).by_channel_type(YoutubeChannel.channel_type.find_value(:business).value.to_s).by_filled(true.to_s).by_last_event_time('youtube_channels', 'updated_at', youtube_channels_period).references(google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]).size
          filled_business_channels_url = youtube_channels_path(channel_type: YoutubeChannel.channel_type.find_value(:business).value.to_s, filled: true, table_name: 'youtube_channels', field_name: 'updated_at', last_time: youtube_channels_period, bot_server_id: youtube_channels_bot_server.try(:id), client_id: youtube_channels_client.try(:id))
					unfilled_business_channels_size = YoutubeChannel.distinct.includes(google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]).by_display_all(nil).by_bot_server_id(youtube_channels_bot_server.try(:id)).by_client_id(youtube_channels_client.try(:id)).by_channel_type(YoutubeChannel.channel_type.find_value(:business).value.to_s).by_filled(false.to_s).by_last_event_time('youtube_channels', 'updated_at', youtube_channels_period).references(google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]).size
          unfilled_business_channels_url = youtube_channels_path(channel_type: YoutubeChannel.channel_type.find_value(:business).value.to_s, filled: false, table_name: 'youtube_channels', field_name: 'updated_at', last_time: youtube_channels_period, bot_server_id: youtube_channels_bot_server.try(:id), client_id: youtube_channels_client.try(:id))
          pending_approval_business_channels_size = YoutubeChannel.distinct.includes(google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]).by_display_all(nil).by_bot_server_id(youtube_channels_bot_server.try(:id)).by_client_id(youtube_channels_client.try(:id)).by_channel_type(YoutubeChannel.channel_type.find_value(:business).value.to_s).by_ready(false.to_s).by_last_event_time('youtube_channels', 'updated_at', youtube_channels_period).references(google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]).size
          pending_approval_business_channels_url = youtube_channels_path(channel_type: YoutubeChannel.channel_type.find_value(:business).value.to_s, ready: false, table_name: 'youtube_channels', field_name: 'updated_at', last_time: youtube_channels_period, bot_server_id: youtube_channels_bot_server.try(:id), client_id: youtube_channels_client.try(:id))
          not_associated_websites_size = YoutubeChannel.distinct.joins("LEFT OUTER JOIN google_accounts ON google_accounts.id = youtube_channels.google_account_id LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id RIGHT JOIN associated_websites on associated_websites.youtube_channel_id = youtube_channels.id").by_display_all(nil).by_bot_server_id(youtube_channels_bot_server.try(:id)).by_client_id(youtube_channels_client.try(:id)).by_channel_type(YoutubeChannel.channel_type.find_value(:business).value.to_s).by_associated_websites(false.to_s).by_last_event_time('associated_websites', 'updated_at', youtube_channels_period).size
          not_associated_websites_url = youtube_channels_path(channel_type: YoutubeChannel.channel_type.find_value(:business).value.to_s, associated: false, table_name: 'associated_websites', field_name: 'updated_at', last_time: youtube_channels_period, bot_server_id: youtube_channels_bot_server.try(:id), client_id: youtube_channels_client.try(:id))
          #associated_websites_size = phone_verified_business_channels_size - not_associated_websites_size

          #videos
          #total videos
          total_pending_approval_videos_size = YoutubeVideo.includes(youtube_channel: [google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]]).by_display_all(nil).by_ready(false.to_s).by_linked(false.to_s).by_deleted(false.to_s).references(youtube_channel: [google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]]).size
          total_pending_approval_videos_url = youtube_videos_path(ready: false, linked: false, deleted: false)
          videos_size = YoutubeVideo.includes(youtube_channel: [google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]]).by_display_all(nil).references(youtube_channel: [google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]]).size
          videos_url = youtube_videos_path()
          total_published_videos_size = YoutubeVideo.includes(youtube_channel: [google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]]).by_display_all(nil).by_deleted(false.to_s).by_is_active(true.to_s).by_ready(true.to_s).references(youtube_channel: [google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]]).size
          total_published_videos_url = youtube_videos_path(deleted: false, is_active: true, ready: true)
          total_not_published_videos_size = YoutubeVideo.includes(youtube_channel: [google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]]).by_display_all(nil).by_deleted(false.to_s).by_is_active(false.to_s).by_ready(true.to_s).by_last_event_time('youtube_videos', 'updated_at', nil).references(youtube_channel: [google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]]).size
          total_not_published_videos_url = youtube_videos_path(deleted: false, is_active: false, ready: true)
          total_deleted_videos_size = YoutubeVideo.includes(youtube_channel: [google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]]).by_display_all(nil).by_deleted(true.to_s).by_is_active(false.to_s).references(youtube_channel: [google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]]).size
          total_deleted_videos_url = youtube_videos_path(deleted: true, is_active: false)

          published_videos_size = YoutubeVideo.includes(youtube_channel: [google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]]).by_display_all(nil).by_bot_server_id(youtube_videos_bot_server.try(:id)).by_client_id(youtube_videos_client.try(:id)).by_deleted(false.to_s).by_is_active(true.to_s).by_ready(true.to_s).by_last_event_time('youtube_videos', 'publication_date', youtube_videos_period).references(youtube_channel: [google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]]).size
          published_videos_url = youtube_videos_path(deleted: false, is_active: true, ready: true, table_name: 'youtube_videos', field_name: 'publication_date', last_time: youtube_videos_period, bot_server_id: youtube_videos_bot_server.try(:id), client_id: youtube_videos_client.try(:id))
          not_published_videos_size = YoutubeVideo.includes(youtube_channel: [google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]]).by_display_all(nil).by_bot_server_id(youtube_videos_bot_server.try(:id)).by_client_id(youtube_videos_client.try(:id)).by_deleted(false.to_s).by_is_active(false.to_s).by_ready(true.to_s).by_last_event_time('youtube_videos', 'updated_at', youtube_videos_period).references(youtube_channel: [google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]]).size
          not_published_videos_url = youtube_videos_path(deleted: false, is_active: false, ready: true, table_name: 'youtube_videos', field_name: 'updated_at', last_time: youtube_videos_period, bot_server_id: youtube_videos_bot_server.try(:id), client_id: youtube_videos_client.try(:id))
          deleted_videos_size = YoutubeVideo.includes(youtube_channel: [google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]]).by_display_all(nil).by_bot_server_id(youtube_videos_bot_server.try(:id)).by_client_id(youtube_videos_client.try(:id)).by_deleted(true.to_s).by_is_active(false.to_s).by_last_event_time('youtube_videos', 'updated_at', youtube_videos_period).references(youtube_channel: [google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]]).size
          deleted_videos_url = youtube_videos_path(deleted: true, is_active: false, table_name: 'youtube_videos', field_name: 'updated_at', last_time: youtube_videos_period, bot_server_id: youtube_videos_bot_server.try(:id), client_id: youtube_videos_client.try(:id))
          pending_approval_videos_size = YoutubeVideo.includes(youtube_channel: [google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]]).by_display_all(nil).by_bot_server_id(youtube_videos_bot_server.try(:id)).by_client_id(youtube_videos_client.try(:id)).by_ready(false.to_s).by_linked(false.to_s).by_deleted(false.to_s).by_last_event_time('youtube_videos', 'updated_at', youtube_videos_period).references(youtube_channel: [google_account: [{email_account: [{locality: [{primary_region: [:country]}]}, :client]}]]).size
          pending_approval_videos_url = youtube_videos_path(ready: false, linked: false, deleted: false, table_name: 'youtube_videos', field_name: 'updated_at', last_time: youtube_videos_period, bot_server_id: youtube_videos_bot_server.try(:id), client_id: youtube_videos_client.try(:id))

          youtube_videos_join = "LEFT OUTER JOIN youtube_channels ON youtube_channels.id = youtube_videos.youtube_channel_id LEFT OUTER JOIN google_accounts ON google_accounts.id = youtube_channels.google_account_id LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id LEFT OUTER JOIN geobase_localities ON geobase_localities.id = email_accounts.locality_id LEFT OUTER JOIN geobase_regions ON geobase_regions.id = geobase_localities.primary_region_id LEFT OUTER JOIN geobase_countries ON geobase_countries.id = geobase_regions.country_id LEFT OUTER JOIN geobase_regions regions ON regions.id = email_accounts.region_id LEFT OUTER JOIN geobase_countries countries ON countries.id = regions.country_id LEFT OUTER JOIN clients ON clients.id = email_accounts.client_id LEFT OUTER JOIN youtube_video_annotations ON youtube_video_annotations.youtube_video_id = youtube_videos.id LEFT OUTER JOIN youtube_video_cards ON youtube_video_cards.youtube_video_id = youtube_videos.id LEFT OUTER JOIN call_to_action_overlays ON call_to_action_overlays.youtube_video_id = youtube_videos.id"
          annotations_posted_size = YoutubeVideo.distinct.joins(youtube_videos_join).by_display_all(nil).by_bot_server_id(youtube_videos_bot_server.try(:id)).by_client_id(youtube_videos_client.try(:id)).by_is_active(true.to_s).by_posted_annotations(true.to_s).by_last_event_time('youtube_video_annotations', 'updated_at', youtube_videos_period).size
          annotations_posted_url = youtube_videos_path(is_active: true, annotations_posted: true, table_name: 'youtube_video_annotations', field_name: 'updated_at', last_time: youtube_videos_period, bot_server_id: youtube_videos_bot_server.try(:id), client_id: youtube_videos_client.try(:id))
					annotations_not_posted_size = YoutubeVideo.distinct.joins(youtube_videos_join).by_display_all(nil).by_bot_server_id(youtube_videos_bot_server.try(:id)).by_client_id(youtube_videos_client.try(:id)).by_is_active(true.to_s).by_posted_annotations(false.to_s).by_last_event_time('youtube_video_annotations', 'updated_at', youtube_videos_period).size
          annotations_not_posted_url = youtube_videos_path(is_active: true, annotations_posted: false, table_name: 'youtube_video_annotations', field_name: 'updated_at', last_time: youtube_videos_period, bot_server_id: youtube_videos_bot_server.try(:id), client_id: youtube_videos_client.try(:id))
					cards_posted_size = YoutubeVideo.distinct.joins(youtube_videos_join).by_display_all(nil).by_bot_server_id(youtube_videos_bot_server.try(:id)).by_client_id(youtube_videos_client.try(:id)).by_is_active(true.to_s).by_posted_cards(true.to_s).by_last_event_time('youtube_video_cards', 'updated_at', youtube_videos_period).size
          cards_posted_url = youtube_videos_path(is_active: true, cards_posted: true, table_name: 'youtube_video_cards', field_name: 'updated_at', last_time: youtube_videos_period, bot_server_id: youtube_videos_bot_server.try(:id), client_id: youtube_videos_client.try(:id))
					cards_not_posted_size = YoutubeVideo.distinct.joins(youtube_videos_join).by_display_all(nil).by_bot_server_id(youtube_videos_bot_server.try(:id)).by_client_id(youtube_videos_client.try(:id)).by_is_active(true.to_s).by_posted_cards(false.to_s).by_last_event_time('youtube_video_cards', 'updated_at', youtube_videos_period).size
          cards_not_posted_url = youtube_videos_path(is_active: true, cards_posted: false, table_name: 'youtube_video_cards', field_name: 'updated_at', last_time: youtube_videos_period, bot_server_id: youtube_videos_bot_server.try(:id), client_id: youtube_videos_client.try(:id))
					call_to_action_overlays_posted_size = YoutubeVideo.distinct.joins(youtube_videos_join).by_display_all(nil).by_bot_server_id(youtube_videos_bot_server.try(:id)).by_client_id(youtube_videos_client.try(:id)).by_is_active(true.to_s).by_posted_call_to_action_overlays(true.to_s).by_last_event_time('call_to_action_overlays', 'updated_at', youtube_videos_period).size
          call_to_action_overlays_posted_url = youtube_videos_path(is_active: true, call_to_action_overlays_posted: true, table_name: 'call_to_action_overlays', field_name: 'updated_at', last_time: youtube_videos_period, bot_server_id: youtube_videos_bot_server.try(:id), client_id: youtube_videos_client.try(:id))
					call_to_action_overlays_not_posted_size = YoutubeVideo.distinct.joins(youtube_videos_join).by_display_all(nil).by_bot_server_id(youtube_videos_bot_server.try(:id)).by_client_id(youtube_videos_client.try(:id)).by_is_active(true.to_s).by_posted_call_to_action_overlays(false.to_s).by_last_event_time('call_to_action_overlays', 'updated_at', youtube_videos_period).size
          call_to_action_overlays_not_posted_url = youtube_videos_path(is_active: true, call_to_action_overlays_posted: false, table_name: 'call_to_action_overlays', field_name: 'updated_at', last_time: youtube_videos_period, bot_server_id: youtube_videos_bot_server.try(:id), client_id: youtube_videos_client.try(:id))
          posted_on_google_plus_videos_size = YoutubeVideo.distinct.joins(youtube_videos_join).by_display_all(nil).by_bot_server_id(youtube_videos_bot_server.try(:id)).by_client_id(youtube_videos_client.try(:id)).by_is_active(true.to_s).by_posted_on_google_plus(true.to_s).by_last_event_time('youtube_videos', 'updated_at', youtube_videos_period).size
          posted_on_google_plus_videos_url = youtube_videos_path(is_active: true, posted_on_google_plus: true, table_name: 'youtube_videos', field_name: 'updated_at', last_time: youtube_videos_period, bot_server_id: youtube_videos_bot_server.try(:id), client_id: youtube_videos_client.try(:id))
          not_posted_on_google_plus_videos_size = YoutubeVideo.distinct.joins(youtube_videos_join).by_display_all(nil).by_bot_server_id(youtube_videos_bot_server.try(:id)).by_client_id(youtube_videos_client.try(:id)).by_is_active(true.to_s).by_posted_on_google_plus(false.to_s).by_last_event_time('youtube_videos', 'updated_at', youtube_videos_period).size
          not_posted_on_google_plus_videos_url = youtube_videos_path(is_active: true, posted_on_google_plus: false, table_name: 'youtube_videos', field_name: 'updated_at', last_time: youtube_videos_period, bot_server_id: youtube_videos_bot_server.try(:id), client_id: youtube_videos_client.try(:id))
					now = Time.now.in_time_zone('Eastern Time (US & Canada)')
					date_from_sms_start = now - now.hour.hours - now.min.minutes - now.sec.seconds + 1.second
					date_sms_limit = now - now.hour.hours - now.min.minutes - now.sec.seconds + 1.second + bot_server.start_business_working_hour.hours
					provide_sms_current_total_size = GoogleAccountActivity.includes(google_account:[:email_account])
						.where("email_accounts.is_active = true AND email_accounts.deleted IS NOT TRUE
							AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value} AND google_accounts.error_type = ?", GoogleAccount::ERROR_TYPES["provide a phone number, we'll send a verification code"])
						.references(google_account:[:email_account]).size
					provide_sms_in_progress_size = GoogleAccountActivity.includes(google_account:[:email_account])
						.where("email_accounts.is_active = true AND email_accounts.deleted IS NOT TRUE
							AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value} AND google_accounts.updated_at > ? AND google_accounts.updated_at < ?
							AND NOT(google_account_activities.activity_end[array_length(google_account_activities.activity_end, 1)] > ?
							OR google_account_activities.activity_end_crash[array_length(google_account_activities.activity_end_crash, 1)] > ?) AND google_accounts.error_type = ?",
							date_from_sms_start.getgm, date_sms_limit.getgm, date_from_sms_start.getgm, date_from_sms_start.getgm, GoogleAccount::ERROR_TYPES["provide a phone number, we'll send a verification code"])
						.references(google_account:[:email_account]).size
					provide_sms_finished_still_need_sms_size = GoogleAccountActivity.includes(google_account:[:email_account])
						.where("email_accounts.is_active = true AND email_accounts.deleted IS NOT TRUE
							AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value} AND google_accounts.updated_at > ? AND google_accounts.updated_at < ?
							AND (google_account_activities.activity_end[array_length(google_account_activities.activity_end, 1)] > ?
							OR google_account_activities.activity_end_crash[array_length(google_account_activities.activity_end_crash, 1)] > ?) AND google_accounts.error_type = ?",
								date_from_sms_start.getgm, date_sms_limit.getgm, date_from_sms_start.getgm, date_from_sms_start.getgm, GoogleAccount::ERROR_TYPES["provide a phone number, we'll send a verification code"])
						.references(google_account:[:email_account]).size
					provide_sms_finished_success_size = GoogleAccountActivity.includes(google_account:[:email_account])
						.where("email_accounts.is_active = true AND email_accounts.deleted IS NOT TRUE
						AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value} AND google_accounts.updated_at > ?
						AND google_accounts.updated_at < ? AND (google_account_activities.activity_end[array_length(google_account_activities.activity_end, 1)] > ?
						OR google_account_activities.activity_end_crash[array_length(google_account_activities.activity_end_crash, 1)] > ?)
						AND (google_accounts.error_type IS NULL OR google_accounts.error_type <> ?)
						AND google_account_activities.verification_code_success_attempt[array_length(google_account_activities.verification_code_success_attempt, 1)] > ?",
							date_from_sms_start.getgm, date_sms_limit.getgm, date_from_sms_start.getgm, date_from_sms_start.getgm,
							GoogleAccount::ERROR_TYPES["provide a phone number, we'll send a verification code"], date_from_sms_start.getgm).references(google_account:[:email_account]).size
			    # date_from = if Setting.get_value_by_name("GoogleAccountActivity::RECOVERY_BOT_RUNNING_STATUS") == false.to_s
					# 	date = now
			    #   date - date.hour.hours - date.min.minutes - date.sec.seconds + 1.second
			    # else
					# 	Setting.find_by_name("GoogleAccountActivity::RECOVERY_BOT_RUNNING_STATUS").updated_at
			    # end
          other_recovery_inbox_emails_size = RecoveryInboxEmail.where("date > ? and email_type = ?", Time.now - 72.hours, RecoveryInboxEmail.email_type.find_value("Other").value).size
          problems << "There #{other_recovery_inbox_emails_size > 1 ? 'are' : 'is'} <a href='/email_accounts?limit=25&recovery_inbox_email_last_time=72&recovery_inbox_email_type=#{RecoveryInboxEmail.email_type.find_value("Other").value}' target='_blank'>#{other_recovery_inbox_emails_size}</a> recovery inbox #{'email'.pluralize(other_recovery_inbox_emails_size)} with type 'Other' for last 72 hours" if other_recovery_inbox_emails_size > 0
          google_recovery_inbox_emails = []
          grie_stats = RecoveryInboxEmail.where("date > ? and sender like '%google%'", Time.now - recovery_inbox_emails_period.hours).group(:email_type).count
          grie_stats = grie_stats.sort {|a,b| b.second <=> a.second}.to_h
					grie_stats.each do |row|
						line = {}
						line['code'] = row.first
						line["name"] = row.first == RecoveryInboxEmail.email_type.find_value("Other").value ? "<span class='warning-td'>#{RecoveryInboxEmail.email_type.find_value(row.first)}</span>" : RecoveryInboxEmail.email_type.find_value(row.first)
						line['count'] = row.second.to_s(:delimited)
						line['url'] = "/email_accounts?limit=25&recovery_inbox_email_last_time=#{recovery_inbox_emails_period}&recovery_inbox_email_type=#{row.first}"
						google_recovery_inbox_emails << line
					end
          youtube_recovery_inbox_emails = []
          yrie_stats = RecoveryInboxEmail.where("date > ? and sender like '%youtube%'", Time.now - recovery_inbox_emails_period.hours).group(:email_type).count
          yrie_stats = yrie_stats.sort {|a,b| b.second <=> a.second}.to_h
					yrie_stats.each do |row|
						line = {}
						line['code'] = row.first
						line["name"] = row.first == RecoveryInboxEmail.email_type.find_value("Other").value ? "<span class='warning-td'>#{RecoveryInboxEmail.email_type.find_value(row.first)}</span>" : RecoveryInboxEmail.email_type.find_value(row.first)
						line['count'] = row.second.to_s(:delimited)
						line['url'] = "/email_accounts?limit=25&recovery_inbox_email_last_time=#{recovery_inbox_emails_period}&recovery_inbox_email_type=#{row.first}"
						youtube_recovery_inbox_emails << line
					end
					date_from = bot_server.recovery_bot_running_status_updated_at.present? ? bot_server.recovery_bot_running_status_updated_at : Time.now
					date_from_getgm = date_from.getgm.to_s
			    # total = GoogleAccountActivity.includes(google_account:[:email_account])
			    #   .where("(email_accounts.is_active = false OR google_account_activities.recovery_answer_date[array_length(google_account_activities.recovery_answer_date, 1)] > ?) AND email_accounts.deleted IS NOT TRUE", date_from.getgm).references(google_account:[:email_account]).size
			    # current_size = GoogleAccountActivity.includes(google_account:[:email_account])
			    #   .where("email_accounts.deleted IS NOT TRUE
			    #     AND google_account_activities.recovery_answer_date[array_length(google_account_activities.recovery_answer_date, 1)] > ?", date_from.getgm)
			    #   .references(google_account:[:email_account]).size
			    # recovery_attempts_percentage = total == 0 ? 0 : current_size * 100 / total
          recovery_attempts_missing_size = EmailAccount.distinct.joins('LEFT OUTER JOIN google_accounts ON email_accounts.email_item_id = google_accounts.id
              LEFT OUTER JOIN google_account_activities ON google_accounts.id = google_account_activities.google_account_id').where("email_accounts.is_active = false AND email_accounts.deleted IS NOT TRUE AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value}").by_recovery_answer("0", "0").size
          recovery_attempts_missing_url = email_accounts_path(account_type: EmailAccount.account_type.find_value(:operational).value, is_active: false, deleted: false, recovery_answer_date_from: 0, recovery_answer: 0)
          recovery_attempts_size = GoogleAccountActivity.includes(google_account:[:email_account])
          .where("email_accounts.is_active = false AND email_accounts.deleted IS NOT TRUE AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value}
          AND google_account_activities.recovery_attempt[array_length(google_account_activities.recovery_attempt, 1)] > ?", (Time.now - 24.hours).getgm)
          .references(google_account:[:email_account]).size
			    recovery_statistics_sql =
					"SELECT answers.answer[array_length(answers.answer, 1)], count(answers.answer[array_length(answers.answer, 1)])
					FROM (SELECT \"google_account_activities\".\"recovery_answer\" as answer
						FROM \"google_account_activities\" LEFT OUTER JOIN \"google_accounts\" ON \"google_accounts\".\"id\" = \"google_account_activities\".\"google_account_id\" LEFT OUTER JOIN \"email_accounts\" ON \"email_accounts\".\"email_item_id\" = \"google_accounts\".\"id\" AND \"email_accounts\".\"email_item_type\" = 'GoogleAccount'
					  WHERE email_accounts.deleted IS NOT TRUE AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value}
			      AND google_account_activities.recovery_answer_date[array_length(google_account_activities.recovery_answer_date, 1)] > '#{(Time.now - recovery_attempt_answers_period.hours).getgm}'
					  ORDER BY google_account_activities.updated_at asc) as answers
				  GROUP BY answers.answer[array_length(answers.answer, 1)]
				  ORDER BY answers.answer[array_length(answers.answer, 1)];"
					rec_stats = ActiveRecord::Base.connection.execute(recovery_statistics_sql)
					recovery_statistics = []
					rec_stats.each do |row|
						line = {}
						line['answer'] = row['answer']
						line["name"] = GoogleAccountActivity::RECOVERY_ANSWERS.key(row['answer'].to_i)
						line['count'] = row['count'].to_i.to_s(:delimited)
						line['url'] = "/email_accounts?limit=25&recovery_answer_date_from=#{(Time.now - recovery_attempt_answers_period.hours).getgm}&recovery_answer=#{row['answer']}"
						recovery_statistics << line
					end
					# recovery_attempt_style = 'progress-bar progress-bar-primary'
					# recovery_attempt_text = 'Process is running now'
					# if !Utils.open_for_business?(false, now)
					# 	recovery_attempt_text = 'Process is sleeping now'
					# 	recovery_attempt_style = 'progress-bar progress-bar-success'
					# end
					# recovery_attempt_text += " (#{recovery_attempts_percentage}% Done)"
          phone_usages_statistics_sql =
          "SELECT action_type, error_type, count(id) as count
            FROM phone_usages
            WHERE created_at >= '#{(Time.now - phone_usages_period.days).getgm}' AND created_at <= '#{Time.now.getgm}'
            GROUP BY action_type, error_type
            ORDER BY action_type, error_type DESC;"
          phone_usages_stats = ActiveRecord::Base.connection.execute(phone_usages_statistics_sql)
          phone_usages_statistics = []
          phone_usages_stats.each do |row|
            line = {}
            line['action_type'] = row['action_type'].present? ? PhoneUsage::ACTION_TYPES.key(row['action_type'].to_i).try(:humanize) : "Unknown"
            line['error_type'] = row['error_type'].present? ? PhoneUsage::ERROR_TYPES.key(row['error_type'].to_i).try(:humanize) : "-"
            sms_code_presence = row['error_type'].present? ? "" : true
            error_type = row['error_type'].present? ? row['error_type'] : 0
            line['url'] = "/phone_usages?action_type=#{row['action_type']}&error_type=#{error_type}&last_days=#{phone_usages_period}&sms_code_presence=#{sms_code_presence}"
            line['count'] = row['count'].to_i.to_s(:delimited)
            phone_usages_statistics << line
          end
					api_accounts_statistics = []
					api_accounts = ApiAccount.where("currency IS NOT NULL").order(:name)
					api_accounts.each do |aa|
						api_account_json = {}
						api_account_json['id'] = aa.id
						api_account_json['url'] = edit_api_account_path(aa)
						api_account_json['name'] = aa.name
						api_account_json['current_bid'] = aa.resource.try(:current_bid).try(:round, 2).to_s
						api_account_json['success_attempts_size'] = aa.resource_type == 'PhoneServiceAccount' ? PhoneUsage.where("phone_service_account_id = ? AND sms_code IS NOT NULL", aa.resource_id).size.to_s(:delimited) : ""
						api_account_json['unsuccess_attempts_size'] = aa.resource_type == 'PhoneServiceAccount' ? PhoneUsage.where("phone_service_account_id = ? AND sms_code IS NULL", aa.resource_id).size.to_s(:delimited) : ""
						api_account_json['balance'] = aa.try(:balance).present? ? aa.balance.try(:round, 2).to_s(:delimited) : ""
						api_account_json['currency'] = aa.try(:currency).present? ? aa.currency.try(:first, 3).try(:downcase) : ""
						api_accounts_statistics << api_account_json
					end
					dids_statistics_sql =
					"SELECT geobase_countries.code as country_code, geobase_regions.name as region_name, phones.country_id, phones.region_id, count(phones.id) as cnt
					FROM phones INNER JOIN geobase_countries ON geobase_countries.id = phones.country_id INNER JOIN geobase_regions ON geobase_regions.id = phones.region_id
					WHERE phones.phone_provider_id = #{@did_phone_provider_id}
					GROUP BY geobase_countries.code, geobase_regions.name , phones.region_id, phones.country_id
					ORDER BY geobase_countries.code, cnt DESC;"
					dids_stats = ActiveRecord::Base.connection.execute(dids_statistics_sql)
					dids_statistics = []
					dids_stats.each do |row|
						line = {}
						line['country_code'] = row['country_code']
						line['region_name'] = row['region_name']
						line['by_country_url'] = "/phones?country_id=#{row['country_id']}&phone_provider_id=#{@did_phone_provider_id}"
						line['url'] = "/phones?country_id=#{row['country_id']}&region_id=#{row['region_id']}&phone_provider_id=#{@did_phone_provider_id}"
						line['count'] = row['cnt'].to_i.to_s(:delimited)
						dids_statistics << line
					end
					dids_size = Phone.where("phone_provider_id = ?", @did_phone_provider_id).size
					youtube_channels_average_posting_time = YoutubeChannel.average_posting_time(youtube_channels_period, youtube_channels_bot_server.try(:id), youtube_channels_client.try(:id))
					associated_website_average_time = AssociatedWebsite.average_posting_time(youtube_channels_period, youtube_channels_bot_server.try(:id), youtube_channels_client.try(:id))
          adwords_campaigns_average_time = AdwordsCampaign.average_posting_time(youtube_videos_period, youtube_videos_bot_server.try(:id), youtube_videos_client.try(:id))
          adwords_campaign_groups_average_time = AdwordsCampaignGroup.average_posting_time(youtube_videos_period, youtube_videos_bot_server.try(:id), youtube_videos_client.try(:id))
          call_to_action_overlays_average_time = CallToActionOverlay.average_posting_time(youtube_videos_period, youtube_videos_bot_server.try(:id), youtube_videos_client.try(:id))
          youtube_video_annotations_average_time = YoutubeVideoAnnotation.average_posting_time(youtube_videos_period, youtube_videos_bot_server.try(:id), youtube_videos_client.try(:id))
          youtube_video_cards_average_time = YoutubeVideoCard.average_posting_time(youtube_videos_period, youtube_videos_bot_server.try(:id), youtube_videos_client.try(:id))
          google_plus_upload_average_time = YoutubeVideo.average_google_plus_upload_time(youtube_videos_period, youtube_videos_bot_server.try(:id), youtube_videos_client.try(:id))
          youtube_videos_average_posting_time = YoutubeVideo.average_posting_time(youtube_videos_period, youtube_videos_bot_server.try(:id), youtube_videos_client.try(:id))
          clients_statistics = []
          active_clients_with_assets = Client.distinct.joins("LEFT OUTER JOIN industries ON industries.id = clients.industry_id
          LEFT OUTER JOIN client_landing_pages ON clients.id = client_landing_pages.client_id
          LEFT OUTER JOIN email_accounts ON clients.id = email_accounts.client_id")
          .by_is_active(true.to_s)
          .by_has_assets(true.to_s)
          .order(name: :asc)
          active_clients_with_assets.each do |client|
            line = {}
            line['name'] = client.name
            line['legend_url'] = legend_client_path(client)
            clients_statistics << line
          end
          Setting.get_value_by_name("EmailAccount::LAST_ORDER_ACCOUNTS_NUMBER")
          accounts_number_setting = Setting.find_by_name("EmailAccount::LAST_ORDER_ACCOUNTS_NUMBER")
          accounts_created = EmailAccount.where("created_at > ?", accounts_number_setting.updated_at).size
          show_account_creation_progress = (accounts_number_setting.value.to_i > accounts_created && accounts_number_setting.value.to_i > 0) ? true : false
					video_workflow_rendering_join = "LEFT JOIN blended_video_chunks ON blended_video_chunks.blended_video_id = blended_videos.id LEFT JOIN templates_dynamic_aae_projects ON templates_dynamic_aae_projects.id = blended_video_chunks.templates_dynamic_aae_project_id"
          #TODO: count video_workflow_rendering_in_progress_size and video_workflow_rendering_total_size
					video_workflow_rendering_in_progress_size = nil
          video_workflow_rendering_done_size = BlendedVideo.where("blended_video_completed(blended_videos.id)::int = 1 AND blended_videos.created_at > ?", Time.now - video_workflow_period.hours).size

          video_workflow_content_creation_done_blended_video_ids = YoutubeVideo.where("created_at > ?", Time.now - video_workflow_period.hours).pluck(:blended_video_id).compact

          video_workflow_blending_in_progress_size = Delayed::Job.where("handler like '%BlendedVideos::BlendVideoSetJob%' AND created_at > ?", Time.now - video_workflow_period.hours).count

          video_workflow_blending_done_size = BlendedVideo.accepted.where("blended_videos.updated_at > ? AND file_file_name is not null", Time.now - video_workflow_period.hours).size

          video_workflow_content_creation_in_progress_size = BlendedVideo.accepted.where("blended_videos.file_updated_at > ? AND blended_videos.id not in (?)", Time.now - video_workflow_period.hours, video_workflow_content_creation_done_blended_video_ids.present? ? video_workflow_content_creation_done_blended_video_ids : [-1]).size
          video_workflow_content_creation_done_size = video_workflow_content_creation_done_blended_video_ids.size

          templates_aae_projects_sql = "SELECT project_type, is_approved, count(id) FROM templates_aae_projects GROUP BY project_type, is_approved ORDER BY project_type, is_approved"
          templates_aae_projects_result = ActiveRecord::Base.connection.execute(templates_aae_projects_sql)
          templates_aae_projects_hash = {}
            templates_aae_projects_result.each do |r|
            project_type = Templates::AaeProject::TYPES.key(r['project_type'].to_i).to_s.titleize.humanize
            is_approved = r['is_approved'] == 't'
            templates_aae_projects_hash[project_type] = {} unless templates_aae_projects_hash[project_type].present?
            templates_aae_projects_hash[project_type][true] = 0 unless templates_aae_projects_hash[project_type][true].present?
            templates_aae_projects_hash[project_type][false] = 0 unless templates_aae_projects_hash[project_type][false].present?
            templates_aae_projects_hash[project_type][is_approved] = r['count'].to_i
            templates_aae_projects_hash[project_type]["url"] = "/templates?q[project_type_eq]=#{r['project_type'].to_i}&q[is_approved_eq]="
          end
          approved_aae_project_templates = 0
          not_approved_aae_project_templates = 0
          templates_aae_projects_hash.each_pair {|k, v| approved_aae_project_templates += v[true]; not_approved_aae_project_templates += v[false]}
          templates_aae_projects_hash["Total"] = {}
          templates_aae_projects_hash["Total"][true] = approved_aae_project_templates
          templates_aae_projects_hash["Total"][false] = not_approved_aae_project_templates
          templates_aae_projects_hash["Total"]["url"] = "/templates?q[is_approved_eq]="

          broadcaster_hdds = []
          database_hdds = []
          nas_hdds = []
          broadcaster_cpu_load_average = []
          database_cpu_load_average = []
          nas_cpu_load_average = []
          broadcaster_memory = []
          database_memory = []
          nas_memory = []
          alert_system = false
          nas_total_size = Setting.get_value_by_name("Utils::NAS_TOTAL_SIZE")
          if Rails.env.production?
            broadcaster_cpu_cores = %x(grep processor /proc/cpuinfo | wc -l)
            broadcaster_cpu_load_average = %x(cat /proc/loadavg).to_s.split(" ").first(3).map{|x| (x.to_f / broadcaster_cpu_cores.to_i * 100).round(2).to_s + "%"}
            broadcaster_cpu_load_average << broadcaster_cpu_cores
            #temporary display HDD info from broadcaster
            broadcaster_hdds = %x(df -h).to_s.split("\n").map {|x| x.split(" ")}
            broadcaster_hdds.shift
            broadcaster_hdds.reject! {|x| !x[0].include?("/")}
            #broadcaster_hdds.sort! {|x, y| y[4].to_i <=> x[4].to_i}
            broadcaster_hdds.reject! {|x| !x[0].include?("/") || ["/mnt/nas/storage", "/mnt/nas/system", "/mnt/nas/artifacts"].include?(x[5]) }
            if broadcaster_hdds.present?
              if broadcaster_hdds[0][4].to_i > 85
                alert_system = true
                broadcaster_hdds[0][4] = "<span class='alert-td blink'>#{broadcaster_hdds[0][4]}</span>"
                problems << "Broadcaster web server's used space is #{broadcaster_hdds[0][4]}"
              elsif broadcaster_hdds[0][4].to_i > 70
                broadcaster_hdds[0][4] = "<span class='warning-td'>#{broadcaster_hdds[0][4]}</span>"
                problems << "Broadcaster web server's used space is #{broadcaster_hdds[0][4]}"
              end
            end
            broadcaster_free_m = %x(free -mh).to_s.split("\n").map {|x| x.split(" ")}
            broadcaster_free_m.reject! {|x| x[0].include?("-/+")}
            broadcaster_memory << broadcaster_free_m[1]
            broadcaster_memory << broadcaster_free_m[2] + ["-", "-", "-"]
            broadcaster_memory[0][0] = "RAM"
            broadcaster_memory[1][0] = "Swap"
            ["10.50.50.244", "10.50.50.93", "10.50.50.94"].each_with_index do |dj_server_ip, index|
              json_text["delayed_jobs_#{index}_hdds"] = []
              json_text["delayed_jobs_#{index}_cpu_load_average"] = []
              json_text["delayed_jobs_#{index}_memory"] = []
              begin
                Net::SSH.start(dj_server_ip, "broadcaster") do |ssh|
                  delayed_jobs_hdds = []
                  delayed_jobs_cpu_load_average = []
                  delayed_jobs_memory = []
                  result = ssh.exec!("df -h")
                  delayed_jobs_cpu_cores = ssh.exec!("grep processor /proc/cpuinfo | wc -l")
                  delayed_jobs_cpu_load_average = ssh.exec!("cat /proc/loadavg").to_s.split(" ").first(3).map{|x| (x.to_f / delayed_jobs_cpu_cores.to_i * 100).round(2).to_s + "%"}
                  delayed_jobs_free_m = ssh.exec!("free -mh").to_s.split("\n").map {|x| x.split(" ")}
                  ssh.close
                  delayed_jobs_hdds = result.to_s.split("\n").map {|x| x.split(" ")}
                  delayed_jobs_hdds.shift
                  delayed_jobs_hdds.reject! {|x| !x[0].include?("/") || ["/mnt/nas/storage", "/mnt/nas/system", "/mnt/nas/artifacts"].include?(x[5]) }
                  if delayed_jobs_hdds.present?
                    if delayed_jobs_hdds[0][4].to_i > 85
                      alert_system = true
                      delayed_jobs_hdds[0][4] = "<span class='alert-td blink'>#{delayed_jobs_hdds[0][4]}</span>"
                      problems << "Delayed Job server's ##{index + 1} used space is #{delayed_jobs_hdds[0][4]}"
                    elsif delayed_jobs_hdds[0][4].to_i > 70
                      delayed_jobs_hdds[0][4] = "<span class='warning-td'>#{delayed_jobs_hdds[0][4]}</span>"
                      problems << "Delayed Job server's ##{index + 1} used space is #{delayed_jobs_hdds[0][4]}"
                    end
                  end
                  delayed_jobs_cpu_load_average << delayed_jobs_cpu_cores
                  delayed_jobs_free_m.reject! {|x| x[0].include?("-/+")}
                  delayed_jobs_free_m[1][0] = "RAM:"
                  delayed_jobs_memory << delayed_jobs_free_m[1]
                  delayed_jobs_memory << delayed_jobs_free_m[2] + ["-", "-", "-"]
                  delayed_jobs_memory[0][0] = "RAM"
                  delayed_jobs_memory[1][0] = "Swap"
                  json_text["delayed_jobs_#{index}_hdds"] = delayed_jobs_hdds
                  json_text["delayed_jobs_#{index}_cpu_load_average"] = delayed_jobs_cpu_load_average
                  json_text["delayed_jobs_#{index}_memory"] = delayed_jobs_memory
                end
              rescue
                problems << "<span class='warning-td'>Can't connect to Delayed Job server ##{index + 1}</span>"
              end
            end
            begin
              Net::SSH.start("10.50.50.246", "broadcaster") do |ssh|
                result = ssh.exec!("df -h")
                database_cpu_cores = ssh.exec!("grep processor /proc/cpuinfo | wc -l")
                database_cpu_load_average = ssh.exec!("cat /proc/loadavg").to_s.split(" ").first(3).map{|x| (x.to_f / database_cpu_cores.to_i * 100).round(2).to_s + "%"}
                database_free_m = ssh.exec!("free -mh").to_s.split("\n").map {|x| x.split(" ")}
                ssh.close
                database_hdds = result.to_s.split("\n").map {|x| x.split(" ")}
                database_hdds.shift
                database_hdds.reject! {|x| !x[0].include?("/")}
                if database_hdds.present?
                  if database_hdds[0][4].to_i > 85
                    alert_system = true
                    database_hdds[0][4] = "<span class='alert-td blink'>#{database_hdds[0][4]}</span>"
                    problems << "Database server's used space is #{database_hdds[0][4]}"
                  elsif database_hdds[0][4].to_i > 70
                    database_hdds[0][4] = "<span class='warning-td blink'>#{database_hdds[0][4]}</span>"
                    problems << "Database server's used space is #{database_hdds[0][4]}"
                  end
                end
                database_cpu_load_average << database_cpu_cores
                database_free_m.reject! {|x| x[0].include?("-/+")}
                database_free_m[1][0] = "RAM:"
                database_memory << database_free_m[1]
                database_memory << database_free_m[2] + ["-", "-", "-"]
                database_memory[0][0] = "RAM"
                database_memory[1][0] = "Swap"
              end
            rescue
              problems << "<span class='warning-td'>Can't connect to Database server</span>"
            end
            begin
              Net::SSH.start("10.50.50.16", "broadcaster") do |ssh|
                result = ssh.exec!("zfs list -p")
                result = result.split("\n").second.split("\s")
                nas_cpu_cores = ssh.exec!("sysctl hw.ncpu").gsub("hw.ncpu: ", "").to_i
                nas_cpu_load_average = ssh.exec!("sysctl vm.loadavg").gsub("vm.loadavg: { ", "").gsub(" }", "").split(" ").map{|x| (x.to_f / nas_cpu_cores.to_f * 100).round(2).to_s + "%"}
                nas_free_m = ssh.exec!("freecolor -b -o").to_s.split("\n").map {|x| x.split(" ")}
                ssh.close
                nas_used_space = result[1].to_i + result[3].to_i
                nas_available_space = result[2].to_i
                nas_total_space = nas_used_space + nas_available_space
                nas_use_percentage = ((nas_used_space / nas_total_space.to_f) * 100).to_i
                nas_use_percentage = if nas_use_percentage > 85
                  alert_system = true
                  problems << "NAS server used space is <span class='alert-td blink'>#{nas_use_percentage}%</span>"
                  "<span class='alert-td blink'>#{nas_use_percentage}%</span>"
                elsif nas_use_percentage > 70
                  problems << "NAS server's used space is <span class='warning-td'>#{nas_use_percentage}%</span>"
                  "<span class='warning-td'>#{nas_use_percentage}%</span>"
                else
                  "#{nas_use_percentage}%"
                end

                nas_hdds = [['DataStore0', number_to_human_size(nas_total_space), number_to_human_size(nas_used_space), number_to_human_size(nas_available_space), nas_use_percentage, result[4]]]
                nas_cpu_load_average << nas_cpu_cores
                (1..2).each do |i|
                  nas_free_m[i].each_with_index do |e, index|
                    nas_free_m[i][index] = number_to_human_size(e) if index != 0
                  end
                end
                nas_free_m[1][0] = "RAM:"
                nas_free_m[1][5] = nas_free_m[1][5] + " / " + nas_free_m[1][6]
                nas_free_m[1][6] = "-"
                nas_memory << nas_free_m[1]
                nas_memory << nas_free_m[2] + ["-", "-", "-"]
                nas_memory[0][0] = "RAM"
                nas_memory[1][0] = "Swap"
              end
            rescue
              problems << "<span class='warning-td'>Can't connect to NAS server</span>"
            end
          end

          problems << "<span class='warning-td'>Didn't grab IP Addresses Ratings</span>" unless IpAddress.rating_successfully_finished?

          crawler_statuses_total = Job.where("queue = 'geobase_localities_init'").size
			    crawler_statuses_current_size = Job.where("queue = 'geobase_localities_init' AND status IS NOT NULL").size
			    crawler_statuses_percentage = crawler_statuses_total == 0 ? 0 : crawler_statuses_current_size * 100 / crawler_statuses_total
					crawler_statuses_style = crawler_statuses_current_size == crawler_statuses_total ? 'progress-bar progress-bar-success' : 'progress-bar progress-bar-primary'
					crawler_statuses_text = "#{crawler_statuses_current_size.to_s(:delimited)} / #{crawler_statuses_total.to_s(:delimited)} (#{crawler_statuses_percentage}% Done)"
          crawler_statuses = if crawler_statuses_period.present?
            Job.where("queue = 'geobase_localities_init' AND status IS NOT NULL AND updated_at > ?", Time.now - crawler_statuses_period.hours).group(:status).order('status asc').count('id')
          else
            Job.where("queue = 'geobase_localities_init' AND status IS NOT NULL").group(:status).order('status asc').count('id')
          end
          crawler_statuses_statistics = []
					crawler_statuses.each do |key, value|
						line = {}
						line["status"] = Job.status.find_value(key) || "In queue"
						line["count"] = value.to_s(:delimited)
						crawler_statuses_statistics << line
					end
          crawler_in_queue = Job.where("queue = 'geobase_localities_init' AND status IS NULL").group(:status).count('id')
          crawler_statuses_statistics << {"status" => "In queue", "count" => "#{crawler_in_queue[nil].to_s(:delimited)}"} if crawler_in_queue.present?
          #crawler_statuses_statistics << {"status" => "<b>Total</b>", "count" => "<b>#{crawler_statuses_total.to_s(:delimited)}</b>"}
          crawler_statuses_average_running_time = Job.average_running_time(crawler_statuses_period)
          crawler_statuses_maximum_running_time = Job.maximum_running_time(crawler_statuses_period)
          crawler_statuses_minimum_running_time = Job.minimum_running_time(crawler_statuses_period)

					json_text["active_email_accounts_size"] = active_email_accounts_size.to_i.to_s(:delimited)
					json_text["inactive_email_accounts_size"] = inactive_email_accounts_size.to_i.to_s(:delimited)
          json_text["recovery_email_sync_size"] = recovery_email_sync_size.to_i.to_s(:delimited)
          json_text["not_recovery_email_sync_size"] = not_recovery_email_sync_size.to_i.to_s(:delimited)
					json_text["deleted_email_accounts_size"] = deleted_email_accounts_size.to_i.to_s(:delimited)
					json_text["lost_email_accounts_size"] = lost_email_accounts_size.to_i.to_s(:delimited)
					json_text["with_recovery_phone_assigned_size"] = with_recovery_phone_assigned_size.to_i.to_s(:delimited)
					json_text["without_recovery_phone_assigned_size"] = without_recovery_phone_assigned_size.to_i.to_s(:delimited)
					json_text["waiting_recovery_phone_assigned_size"] = waiting_recovery_phone_assigned_size.to_i.to_s(:delimited)
					json_text["suspended_recovery_phone_assigned_size"] = suspended_recovery_phone_assigned_size.to_i.to_s(:delimited)
					json_text["has_alternate_email_size"] = has_alternate_email_size.to_i.to_s(:delimited)
					json_text["has_no_alternate_email_size"] = has_no_alternate_email_size.to_i.to_s(:delimited)
					json_text["has_recovery_email_size"] = has_recovery_email_size.to_i.to_s(:delimited)
					json_text["has_no_recovery_email_size"] = has_no_recovery_email_size.to_i.to_s(:delimited)
          json_text["assigned_to_client_accounts_size"] = assigned_to_client_accounts_size.to_i.to_s(:delimited)
          json_text["not_assigned_to_client_accounts_size"] = not_assigned_to_client_accounts_size.to_i.to_s(:delimited)
					json_text["provide_sms_current_total_size"] = provide_sms_current_total_size.to_i.to_s(:delimited)
					json_text["provide_sms_in_progress_size"] = (provide_sms_current_total_size > 0 && provide_sms_current_total_size <= provide_sms_in_progress_size) ? provide_sms_in_progress_size.to_i.to_s(:delimited) : 0
					json_text["provide_sms_finished_still_need_sms_size"] = provide_sms_finished_still_need_sms_size.to_i.to_s(:delimited)
					json_text["provide_sms_finished_success_size"] = provide_sms_finished_success_size.to_i.to_s(:delimited)
					# json_text["recovery_attempts_percentage"] = recovery_attempts_percentage
					json_text["recovery_attempts_size"] = recovery_attempts_size
					json_text["recovery_statistics"] = recovery_statistics
          json_text["google_recovery_inbox_emails"] = google_recovery_inbox_emails
          json_text["youtube_recovery_inbox_emails"] = youtube_recovery_inbox_emails
          json_text["crawler_statuses_statistics"] = crawler_statuses_statistics
          json_text["crawler_statuses_percentage"] = crawler_statuses_percentage
          json_text["crawler_statuses_style"] = crawler_statuses_style
					json_text["crawler_statuses_text"] = crawler_statuses_text
          json_text["phone_usages_statistics"] = phone_usages_statistics
					json_text["dids_statistics"] = dids_statistics
					json_text["dids_size"] = dids_size
					json_text["api_accounts_statistics"] = api_accounts_statistics
					json_text["date_from"] = date_from.try(:in_time_zone, 'Eastern Time (US & Canada)').try(:strftime, "%m/%d/%y %I:%M %p")
					# json_text["recovery_attempt_style"] = recovery_attempt_style
					# json_text["recovery_attempt_text"] = recovery_attempt_text
          json_text["channels_size"] = channels_size.to_i.to_s(:delimited)
					json_text["published_business_channels_size"] = published_business_channels_size.to_i.to_s(:delimited)
					json_text["not_published_business_channels_size"] = not_published_business_channels_size.to_i.to_s(:delimited)
          json_text["pending_approval_business_channels_size"] = pending_approval_business_channels_size.to_i.to_s(:delimited)
          json_text["not_created_by_phone_business_channels_size"] = not_created_by_phone_business_channels_size.to_i.to_s(:delimited)
					json_text["phone_verified_business_channels_size"] = phone_verified_business_channels_size.to_i.to_s(:delimited)
          json_text["phone_unverified_business_channels_size"] = phone_unverified_business_channels_size.to_i.to_s(:delimited)
					json_text["filled_business_channels_size"] = filled_business_channels_size.to_i.to_s(:delimited)
					json_text["unfilled_business_channels_size"] = unfilled_business_channels_size.to_i.to_s(:delimited)
          #json_text["associated_websites_size"] = associated_websites_size.to_i.to_s(:delimited)

          json_text["broadcaster_hdds"] = broadcaster_hdds
          json_text["database_hdds"] = database_hdds
          json_text["nas_hdds"] = nas_hdds
          json_text["broadcaster_cpu_load_average"] = broadcaster_cpu_load_average
          json_text["database_cpu_load_average"] = database_cpu_load_average
          json_text["nas_cpu_load_average"] = nas_cpu_load_average
          json_text["broadcaster_memory"] = broadcaster_memory
          json_text["database_memory"] = database_memory
          json_text["nas_memory"] = nas_memory

          %w(channels published_business_channels not_published_business_channels created_by_phone_business_channels phone_verified_business_channels phone_unverified_business_channels filled_business_channels unfilled_business_channels pending_approval_business_channels blocked_business_channels not_associated_websites published_videos not_published_videos deleted_videos pending_approval_videos videos posted_on_google_plus_videos not_posted_on_google_plus_videos cards_posted cards_not_posted annotations_posted annotations_not_posted call_to_action_overlays_posted call_to_action_overlays_not_posted total_published_videos total_deleted_videos total_not_published_videos total_published_business_channels total_not_published_business_channels total_blocked_business_channels total_pending_approval_business_channels total_pending_approval_videos active_accounts_recovery_inbox_emails inactive_accounts_recovery_inbox_emails active_accounts_status_changed inactive_accounts_status_changed recovery_attempts_missing active_accounts_pool).each do |s|
            %w(size url).each do |t|
              json_text["#{s}_#{t}"] = "size" == t ? eval("#{s}_#{t}").to_s(:delimited) : eval("#{s}_#{t}")
            end
          end

          json_text["active_accounts_recovery_inbox_email_action_required"] = EmailAccount.unscoped.distinct.joins('LEFT OUTER JOIN google_accounts ON email_accounts.email_item_id = google_accounts.id LEFT OUTER JOIN google_account_activities ON google_accounts.id = google_account_activities.google_account_id LEFT OUTER JOIN recovery_inbox_emails ON recovery_inbox_emails.email_account_id = email_accounts.id').by_display_all(nil).by_is_active(true.to_s).by_account_type(operational_type).by_last_event_time("recovery_inbox_emails", "date", email_accounts_period).where("LOWER(recovery_inbox_emails.body) like '%action required%'").present? ? true : false
          json_text["inactive_accounts_recovery_inbox_email_action_required"] = EmailAccount.unscoped.distinct.joins('LEFT OUTER JOIN google_accounts ON email_accounts.email_item_id = google_accounts.id LEFT OUTER JOIN google_account_activities ON google_accounts.id = google_account_activities.google_account_id LEFT OUTER JOIN recovery_inbox_emails ON recovery_inbox_emails.email_account_id = email_accounts.id').by_display_all(nil).by_is_active(false.to_s).by_account_type(operational_type).by_last_event_time("recovery_inbox_emails", "date", email_accounts_period).where("LOWER(recovery_inbox_emails.body) like '%action required%'").present? ? true : false
          json_text["youtube_videos_average_posting_time"] = youtube_videos_average_posting_time > 0 ? Utils.seconds_to_time(youtube_videos_average_posting_time, true) : "-"
          json_text["youtube_channels_average_posting_time"] = youtube_channels_average_posting_time > 0 ? Utils.seconds_to_time(youtube_channels_average_posting_time, true) : "-"
          json_text["associated_website_average_time"] = associated_website_average_time > 0 ? Utils.seconds_to_time(associated_website_average_time, true) : "-"
          json_text["adwords_campaigns_average_time"] = adwords_campaigns_average_time > 0 ? Utils.seconds_to_time(adwords_campaigns_average_time, true) : "-"
          json_text["adwords_campaign_groups_average_time"] = adwords_campaign_groups_average_time > 0 ? Utils.seconds_to_time(adwords_campaign_groups_average_time, true) : "-"
          json_text["call_to_action_overlays_average_time"] = call_to_action_overlays_average_time > 0 ? Utils.seconds_to_time(call_to_action_overlays_average_time, true) : "-"
          json_text["youtube_video_annotations_average_time"] = youtube_video_annotations_average_time > 0 ? Utils.seconds_to_time(youtube_video_annotations_average_time, true) : "-"
          json_text["youtube_video_cards_average_time"] = youtube_video_cards_average_time > 0 ? Utils.seconds_to_time(youtube_video_cards_average_time, true) : "-"
          json_text["google_plus_upload_average_time"] = google_plus_upload_average_time > 0 ? Utils.seconds_to_time(google_plus_upload_average_time, true) : "-"
          json_text["crawler_statuses_average_running_time"] = crawler_statuses_average_running_time > 0 ? Utils.seconds_to_time(crawler_statuses_average_running_time, true) : "-"
          json_text["crawler_statuses_maximum_running_time"] = crawler_statuses_maximum_running_time > 0 ? Utils.seconds_to_time(crawler_statuses_maximum_running_time, true) : "-"
          json_text["crawler_statuses_minimum_running_time"] = crawler_statuses_minimum_running_time > 0 ? Utils.seconds_to_time(crawler_statuses_minimum_running_time, true) : "-"

          json_text["total_average_online_time"] = GoogleAccountActivity.formatted_average_online_time
          json_text["today_average_online_time"] = GoogleAccountActivity.formatted_today_average_online_time
          json_text["ip_addresses_size"] = IpAddress.all.size
          json_text["clients_active_size"] = active_clients_with_assets.size
          json_text["clients_total_size"] = Client.all.size
          json_text["clients_statistics"] =  clients_statistics
          json_text["ordered_email_accounts_size"] = accounts_number_setting.value.to_i
          json_text["created_email_accounts_size"] = accounts_created
          json_text["show_account_creation_progress"] = show_account_creation_progress
          json_text["templates_aae_projects"] = templates_aae_projects_hash
          json_text["templates_aae_projects_size"] = Templates::AaeProject.all.size.to_s(:delimited)
          json_text["alert_system"] = alert_system
          json_text["problems"] = problems
          json_text["last_success_grab_ip_address_ratings_date"] = Setting.get_value_by_name("IpAddress::LAST_SUCCESS_RATING_GRAB_DATE").try(:to_time).try(:utc).try(:strftime, '%m/%d/%y %I:%M %p UTC')
					progress_types = %w(in_progress done)
					video_workflow_item_types = %w(rendering blending content_creation)
					video_workflow_item_types.each do |it|
						progress_types.each do |pt|
							json_text["video_workflow_#{it}_#{pt}_size"] = eval("video_workflow_#{it}_#{pt}_size").present? ? eval("video_workflow_#{it}_#{pt}_size").to_s(:delimited) : "-"
						end
					end
					calc_methods = %w(sum maximum minimum average)
          %w(view_count subscriber_count comment_count).each do |field|
						calc_methods.each do |cm|
	            json_text["yt_channel_statistics_#{cm}_#{field.gsub('_count', '').pluralize}"] = YoutubeChannel.yt_statistics_data(cm, field).to_s(:delimited)
						end
          end
          %w(view_count like_count dislike_count favorite_count comment_count).each do |field|
						calc_methods.each do |cm|
	            json_text["yt_video_statistics_#{cm}_#{field.gsub('_count', '').pluralize}"] = YoutubeVideo.yt_statistics_data(cm, field).to_s(:delimited)
						end
          end
					render :json => json_text.to_json
				}
			end
		end
end
