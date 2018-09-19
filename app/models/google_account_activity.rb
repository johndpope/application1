require 'utils'

class GoogleAccountActivity < ActiveRecord::Base
	include Workable
	belongs_to :google_account
	has_and_belongs_to_many :watching_video_categories
	# has_and_belongs_to_many :recovery_attempt_responses
	has_many :phone_usages, :as => :phone_usageable
	has_many :jobs, as: :resource, dependent: :destroy
	has_many :recovery_responses, as: :resource, dependent: :destroy
  validates_uniqueness_of :google_account_id

	DAYLY_FIELDS = %w(open_emails delete_emails mark_as_read search watching_videos check_status)
	WEEKLY_FIELDS = %w(stars contacts inbox_categories importance_markers filtered_email chat_status
		chat_emoticons_status forwarding calendar_events to_do_list)
	MONTHLY_FIELDS = %w(theme security_checkup)
	THREE_MONTHS_FIELDS = %w(default_text_style conversation_view profile_photo background archive_email_activity)
	SIX_MONTHS_FIELDS = %w(chat_notifications mail_notifications vacation_responder filters change_spam_settings password_recovery_options
	 secret_question secret_answer account_security_settings)
	ONE_TIME_ACTION_FIELDS = %w(inbox_type chat_auto_add_contacts chat_voice chat_video chat_sounds_status font_signature import_contacts
		send_mail_as other_mail_check email_signature recovery_email)
	UNUSED_FIELDS = %w(first_name last_name locality region country birth_date alternate_email password account_grant_access
		keyboard_shortcuts button_labels personal_level_indicators snippets import_mail pop_settings imap_settings labs offline
		gv_outbound_voice_calling gv_call_forwarding_to_chat gv_work_number gv_number_to_forward gv_voice_mail_greeting gv_recorded_name
		gv_voice_mail_notifications gv_text_forwarding gv_voicemail_pin gv_voicemail_transcripts phone)
	# 21 hours in open_for_business method + 1 hour
	CHECK_INTERVAL = 22
	MINIMUM_WORKING_HOURS = 20
	ACCOUNT_LOGINS_PER_DAY = 2
	RECOVERY_PHONE_ASSIGN_DAYS_INTERVAL = 2
	ACCOUNTS_ASSIGN_RECOVERY_PHONE_PER_DAY_PER_PHONE = 2
	RECOVERY_PHONE_ASSIGN_ENABLED = false
	RECOVERY_PHONE_ASSIGN_CURRENT_QUEUE_ENABLED = true
	#in minutes
	RECOVERY_ATTEMPTS_RETRY_INTERVAL = 60

	#in seconds
	WATCHING_VIDEOS_ALL_AMOUNT = 600
	WATCHING_VIDEOS_MINIMUM = 15
	WATCHING_VIDEOS_MAXIMUM = 180
	SEARCH_SITE_PRESENCE_MINIMUM = 30
	SEARCH_SITE_PRESENCE_MAXIMUM = 300
	SEARCH_TOTAL_TIME = 2400

	SEARCH_SITES_PER_PHRASE_MINIMUM = 3
	SEARCH_SITES_PER_PHRASE_MAXIMUM = 10
	SEARCH_PHRASES_NUMBER = 5
	DO_WATCH_VIDEOS = false
	DO_SEARCH = true
	RECOVERY_BOT_RUNNING_STATUS = false
	RECOVERY_ANSWERS = {"No answer"=>1, "Negative answer"=>2, "Positive answer"=>3, "No longer be recovered"=>4, "Wait for the result"=>5,
		"Deleted account"=>6, "Check status crash"=>7, "Fill the form crash"=>8, "Phone recovery crash"=>9, "Unusual sign in"=>10,
		"Other"=>11, "Recovery is not available"=>12, "Suspended"=>13, "Authentification failed"=>14, "Able to log in normally"=>15}
	ACTIVE_THREADS_STATISTICS_PATH = "/active-threads.php"
	INACTIVE_THREADS_STATISTICS_PATH = "/inactive-threads.php"
	HARDWARE_STATISTICS_PATH = "/hw-stat.php"
	STORING_ONLINE_TIME_START_DATE = "04/11/16"
	ADD_ALTERNATE_EMAIL_DAILY_PER_IP_LIMIT = 2
	TRY_TO_RECOVER_WITH_DID_ENABLED = false
	RECOVERY_ANSWERS_CHECKER_ENABLED = false
	RECOVERY_ACCOUNTS_ACTIVITY_ENABLED = true
  RECOVERY_ACCOUNTS_BATCH_ACTIVITY_ENABLED = false
  SCREENSHOTS_LIMIT = 150
  SCREENSHOTS_LAST_DAYS_LIMIT = 14
  DAILY_ACTIVITY_ENABLED = true
  LOAD_BALANCING_ENABLED = false
  FACEBOOK_ACCOUNTS_CREATION_ENABLED = false
  GOOGLE_PLUS_ACCOUNTS_CREATION_ENABLED = false

	work_queue :google_recovery, repeat_after: nil

	def google_recovery_job_display_name
		google_account.email_account.email
	end

	def acceptable_for_google_recovery?
		[google_account.email_account.is_active, google_account.error_type == GoogleAccount.error_type.find_value("provide a phone number, we'll send a verification code")].all?
  end

  def acceptable_for_gmail_recovery_attempt?
    last_recovery_inbox_email = RecoveryInboxEmail.where(email_account_id: google_account.email_account.id).order(date: :desc).first
    date_range_acceptable = if last_recovery_inbox_email.present? && [RecoveryInboxEmail.email_type.find_value("Wait for the result").value, RecoveryInboxEmail.email_type.find_value("Will review your request and be in touch with an update as soon as possible").value].include?(last_recovery_inbox_email.try(:email_type).try(:value)) && last_recovery_inbox_email.date > Time.now - Setting.get_value_by_name("RecoveryInboxEmail::GMAIL_WAIT_FOR_RESULT_DAYS").to_i.days
      false
    else
      true
    end
    [date_range_acceptable, !google_account.email_account.is_active].all?
  end

  def acceptable_for_recovery_email_sync?
    [google_account.email_account.is_active, !google_account.email_account.recovery_email_sync].all?
  end

	def activity_time
		if activity_start.present?
			if activity_end.present? && activity_end.last > activity_start.last
				Time.at(activity_end.last - activity_start.last).utc.strftime("%H:%M")
			elsif activity_end_crash.present? && activity_end_crash.last > activity_start.last
				Time.at(activity_end_crash.last - activity_start.last).utc.strftime("%H:%M")
			end
		end
	end

	def add_online_time
		if activity_start.present?
			if activity_end.present? && activity_end.last > activity_start.last && (!activity_end_crash.present? || activity_end_crash.last < activity_start.last)
				time = Time.at(activity_end.last - activity_start.last).utc
				self.total_online_time = self.total_online_time.to_i + time.hour*3600 + time.min*60 + time.sec if time.hour < 12
				self.today_online_time = self.today_online_time.to_i + time.hour*3600 + time.min*60 + time.sec if time.hour < 12
			elsif activity_end_crash.present? && activity_end_crash.last > activity_start.last && (!activity_end.present? || activity_end.last < activity_start.last)
				time = Time.at(activity_end_crash.last - activity_start.last).utc
				self.total_online_time = self.total_online_time.to_i + time.hour*3600 + time.min*60 + time.sec if time.hour < 12
				self.today_online_time = self.today_online_time.to_i + time.hour*3600 + time.min*60 + time.sec if time.hour < 12
			end
			self.save
		end
	end

	def average_online_time
		seconds = total_online_time.present? ? total_online_time : 0
		if start_online_at.present?
			seconds = seconds / ((Time.now - start_online_at) / 86400).ceil
		end
		seconds
	end

	def formatted_total_online_time
		Utils.seconds_to_time(average_online_time)
	end

	def formatted_today_online_time
		seconds = today_online_time.present? ? today_online_time : 0
		Utils.seconds_to_time(seconds)
	end

	def self.formatted_average_online_time
		Utils.seconds_to_time(average_online_time)
	end

	def self.formatted_today_average_online_time
		Utils.seconds_to_time(today_average_online_time)
	end

	def recovery_time
		if recovery_attempt_start.present?
			if recovery_attempt.present? && recovery_attempt.last > recovery_attempt_start.last
				Time.at(recovery_attempt.last - recovery_attempt_start.last).utc.strftime("%H:%M")
			elsif recovery_attempt_crash.present? && recovery_attempt_crash.last > recovery_attempt_start.last
				Time.at(recovery_attempt_crash.last - recovery_attempt_start.last).utc.strftime("%H:%M")
			end
		end
	end

	def last_recovery_attempt_date
		if (recovery_attempt_crash.try(:last).present? && recovery_attempt.try(:last).present? && recovery_attempt_crash.try(:last) > recovery_attempt.try(:last)) ||
			(recovery_attempt.try(:last).nil? && recovery_attempt_crash.try(:last).present?)
			recovery_attempt_crash.try(:last).try(:in_time_zone, 'Eastern Time (US & Canada)').try(:strftime, '%m/%d/%y %I:%M %p')
		else
			recovery_attempt.try(:last).try(:in_time_zone, 'Eastern Time (US & Canada)').try(:strftime, '%m/%d/%y %I:%M %p')
		end
	end

	def touch(field, date=Time.now)
		self[field] << date.getgm
		dates = self[field].to_s.gsub("[", "{").gsub("]", "}")
		self.update_column(field, dates)
		self.update_attribute(:updated_at, Time.now)
	end

	def add_recovery_answer(answer)
		self.recovery_answer << answer
		recovery_answers = self.recovery_answer.to_s.gsub("[", "{").gsub("]", "}")
		self.update_column("recovery_answer", recovery_answers)
		self.update_attribute(:updated_at, Time.now)
	end

	def last_recovery_answer
		if self.recovery_answer.present?
			RECOVERY_ANSWERS[self.recovery_answer.last]
		else
			nil
		end
	end

	def self.potential_recovered_accounts(last_days = 2)
		google_account_activities = GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]])
			.where("google_account_activities.recovery_attempt_start[array_length(google_account_activities.recovery_attempt_start, 1)] > (CURRENT_TIMESTAMP - INTERVAL '#{last_days} day') AND email_accounts.is_active = TRUE")
			.references(google_account:[email_account:[:bot_server]])
	end

	def self.start_recovery_assign_process
    bot_servers = if Setting.get_value_by_name("GoogleAccountActivity::LOAD_BALANCING_ENABLED") == false.to_s
      BotServer.where(path: Setting.get_value_by_name("EmailAccount::BOT_URL"))
    else
      BotServer.where(human_emulation: true)
    end
    bot_servers.each do |bot_server|
  		now = Time.now
  		google_account_activities = GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]])
  			.where("email_accounts.is_active = true AND email_accounts.deleted IS NOT TRUE
  				AND email_accounts.recovery_phone_id IS NOT NULL AND email_accounts.recovery_phone_assigned = FALSE AND bot_servers.id = ?", bot_server.id)
  			.references(google_account:[email_account:[:bot_server]])
  		GoogleAccountActivity.where("id in (?)", google_account_activities.map(&:id)).update_all({linked: false, updated_at: now}) if google_account_activities.present?
  		if google_account_activities.size > 0
  			ActiveRecord::Base.logger.info "Recovery phones assign : #{Time.now}"
  			start_job_response = Utils.http_get("#{bot_server.path}/add_activity_count.php", {count: google_account_activities.size}, 3, 10).try(:body).to_s
  			ActiveRecord::Base.logger.info "Start job response: #{start_job_response}"
  		end
    end
	end

	def self.start_recovery_attempt_process(bot_server, all = false)
		now = Time.now.in_time_zone('Eastern Time (US & Canada)')
    date_from = nil
    bot_servers = []
    bot_server ||= BotServer.where(path: Setting.get_value_by_name("EmailAccount::BOT_URL")).first
    if bot_server.present?
      date_from = if all
        bot_server.recovery_bot_running_status_updated_at = Time.now
        bot_server.save
        now
      else
        bot_server.recovery_bot_running_status_updated_at
      end
      bot_servers = if Setting.get_value_by_name("GoogleAccountActivity::LOAD_BALANCING_ENABLED") == false.to_s
        BotServer.where(path: Setting.get_value_by_name("EmailAccount::BOT_URL"))
      else
        [bot_server]
      end
    end
    bot_servers.each do |bot_server|
  		waiting_for_attempt = GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]])
  			.where("email_accounts.is_active = false AND email_accounts.deleted IS NOT TRUE
  				AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value}
  				AND (google_account_activities.recovery_attempt[array_length(google_account_activities.recovery_attempt, 1)] < ?
  				OR google_account_activities.recovery_attempt[array_length(google_account_activities.recovery_attempt, 1)] IS NULL)
  				AND google_account_activities.recovery_answer[array_length(google_account_activities.recovery_answer, 1)] <> ? AND bot_servers.id = ?", date_from.getgm, GoogleAccountActivity::RECOVERY_ANSWERS["Positive answer"], bot_server.id)
  			.references(google_account:[email_account:[:bot_server]])
  		if waiting_for_attempt.size > 0
        GoogleAccountActivity.where("id in (?)", waiting_for_attempt.map(&:id)).update_all({linked: false, updated_at: now})
  			ActiveRecord::Base.logger.info "Recovery attempts : #{now}; size: #{waiting_for_attempt.size}"
  			start_job_response = Utils.http_get("#{bot_server.path}/add_activity_count.php", {count: waiting_for_attempt.size}, 3, 10).try(:body).to_s
  			ActiveRecord::Base.logger.info "Attempt response: #{start_job_response}"
  		end
    end
	end

	def self.fields_updater(bot_servers = [], forced = false)
    if Rails.env.production?
      activities_count = 0
      bot_servers = if bot_servers.present?
        bot_servers
      elsif Setting.get_value_by_name("GoogleAccountActivity::LOAD_BALANCING_ENABLED") == false.to_s
        BotServer.where(path: Setting.get_value_by_name("EmailAccount::BOT_URL"))
      else
        BotServer.where(human_emulation: true)
      end
      bot_servers.each_with_index do |bot_server, index|
        now = Time.now.in_time_zone('Eastern Time (US & Canada)')
        if now.hour == bot_server.start_business_working_hour
          #clear daily online time
          gaa_ids = GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]]).where("bot_servers.id = ?", bot_server.id).references(google_account:[email_account:[:bot_server]]).pluck(:id)
          GoogleAccountActivity.where("id in (?)", gaa_ids).update_all(today_online_time: 0) if gaa_ids.present?
          bot_server.recovery_bot_running_status_updated_at = Time.now
          bot_server.save
        end
        if now.hour == (bot_server.start_business_working_hour - 1)
          if bot_servers.size > 1 && index == 0
            ActiveRecord::Base.logger.info "Collect account screenshots started at: #{now}"
            #delete old screenshots
            email_accounts = EmailAccount.distinct.by_account_type(EmailAccount.account_type.find_value(:operational).value).where("email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value}")
            email_accounts.each do |email_account|
              screenshots = email_account.screenshots.sort.to_a
              screenshots.pop
              screenshots.each do |scr|
                scr.destroy if scr.removable && scr.created_at < (Time.now - Setting.get_value_by_name("GoogleAccountActivity::SCREENSHOTS_LAST_DAYS_LIMIT").to_i.days)
              end
              email_account.reload
              screenshots_limit = Setting.get_value_by_name("GoogleAccountActivity::SCREENSHOTS_LIMIT").to_i
              if email_account.screenshots.size > screenshots_limit
                screenshots = email_account.screenshots.sort.to_a
                screenshots.pop
                screenshots = screenshots - screenshots.last(screenshots_limit)
                screenshots.each do |scr|
                  scr.destroy if scr.removable
                end
              end
              # email_account.save_screenshot(Setting.get_value_by_name("EmailAccount::OTHER_SCREENSHOT_PATH"))
              # email_account.save_screenshot(Setting.get_value_by_name("EmailAccount::SIGN_IN_SCREENSHOT_PATH"))
              # email_account.save_screenshot(Setting.get_value_by_name("EmailAccount::RECOVERY_PHONE_ASSIGN_SCREENSHOT_PATH"))
              # email_account.save_screenshot(Setting.get_value_by_name("EmailAccount::RECOVERY_ATTEMPT_SCREENSHOT_PATH"))
            end
            now = Time.now.in_time_zone('Eastern Time (US & Canada)')
            ActiveRecord::Base.logger.info "Collect account screenshots finished at: #{now}"
          end
          if bot_server.auto_clear_daily_activity_queue
            #clear daily activity queue
            bot_server.clear_daily_activity_queue
          end
        end
        if bot_server.daily_activity_enabled
      		if Utils.open_for_business?(false, now, bot_server) || forced
      			order_by = "case
      				when google_accounts.error_type = #{GoogleAccount::ERROR_TYPES["provide a phone number, we'll send a verification code"]}
      					then 1
      				else
      					null
      				end,
      				random() NULLS LAST"
            total = GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]])
              .where("email_accounts.is_active = true AND email_accounts.deleted IS NOT TRUE AND bot_servers.id = ?", bot_server.id)
              .references(google_account:[email_account:[:bot_server]]).size
            account_logins_per_day = bot_server.account_logins_per_day
            limit_number = total / bot_server.minimum_working_hours * account_logins_per_day + 1
            last_updated_limit = now - (bot_server.check_interval / account_logins_per_day).hours
            google_account_activities = GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]])
            .where("google_account_activities.linked IS NOT FALSE
              AND email_accounts.is_active = true AND email_accounts.deleted IS NOT TRUE
              AND google_account_activities.updated_at < ? AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value} AND bot_servers.id = ?", last_updated_limit, bot_server.id)
            .order(order_by).references(google_account:[email_account:[:bot_server]]).limit(limit_number)

            inactive_google_account_activities = []
            if bot_server.recovery_accounts_activity_enabled
              total_inactive = GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]]).where("email_accounts.is_active = false AND bot_servers.id = ?", bot_server.id).references(google_account:[email_account:[:bot_server]]).size
              limit_number_inactive = total_inactive / bot_server.minimum_working_hours + 1
              inactive_google_account_activities = GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]]).where("google_account_activities.linked IS NOT FALSE AND email_accounts.is_active = false AND (google_account_activities.recovery_attempt[array_length(google_account_activities.recovery_attempt, 1)] < ? OR google_account_activities.recovery_attempt[array_length(google_account_activities.recovery_attempt, 1)] IS NULL) AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value} AND bot_servers.id = ?", bot_server.recovery_bot_running_status_updated_at.getgm, bot_server.id).order("random()").references(google_account:[email_account:[:bot_server]])
              inactive_google_account_activities.reject! {|gaa| !gaa.acceptable_for_gmail_recovery_attempt?}
              inactive_google_account_activities = inactive_google_account_activities.first(limit_number_inactive)
            end

            result_list = google_account_activities + inactive_google_account_activities

            GoogleAccountActivity.where("id in (?)", result_list.shuffle.map(&:id)).update_all({linked: false, updated_at: now}) if result_list.present?

            activities_count = GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]])
              .where("google_account_activities.linked = false AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value} AND bot_servers.id = ?", bot_server.id)
              .references(google_account:[email_account:[:bot_server]]).size

            if activities_count > 0
              ActiveRecord::Base.logger.info "Activities run time : #{now} on #{bot_server.name}"
              start_job_response = Utils.http_get("#{bot_server.path}/add_activity_count.php", {count: activities_count}, 3, 10).try(:body).to_s
              ActiveRecord::Base.logger.info "Start job response: #{start_job_response}"
              ActiveRecord::Base.logger.info "Inactive accounts : #{inactive_google_account_activities.size}"
            end
            activities_count
      		else
            if now.hour == (bot_server.start_business_working_hour - 3)
              if bot_server.recovery_accounts_batch_activity_enabled == true
                GoogleAccountActivity.start_recovery_attempt_process(bot_server)
              end
            end
      			if now.hour == (bot_server.start_business_working_hour - 2)
              IpAddress.update_rating_statistics if index == 0
              bot_servers.each do |bot_server|
        				google_account_activities = GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]])
        				.where("email_accounts.is_active = true AND google_account_activities.linked IS NOT FALSE
        					AND email_accounts.deleted IS NOT TRUE AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value}
        					AND google_accounts.error_type = ? AND bot_servers.id = ?", GoogleAccount::ERROR_TYPES["provide a phone number, we'll send a verification code"], bot_server.id)
        				.order("random()").references(google_account:[email_account:[:bot_server]])

        				ActiveRecord::Base.logger.info "Activities with sms ids: " + google_account_activities.map(&:id).to_s

        				GoogleAccountActivity.where("id in (?)", google_account_activities.map(&:id)).update_all({linked: false, updated_at: now}) if google_account_activities.present?

        				activities_count = GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]])
        					.where("email_accounts.is_active = true AND google_account_activities.linked = false AND email_accounts.deleted IS NOT TRUE
        						AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value} AND google_accounts.error_type = ? AND bot_servers.id = ?", GoogleAccount::ERROR_TYPES["provide a phone number, we'll send a verification code"], bot_server.id)
        					.references(google_account:[email_account:[:bot_server]]).size

        				if activities_count > 0
        					ActiveRecord::Base.logger.info "Activities with sms run time : #{now}"
        					start_job_response = Utils.http_get("#{bot_server.path}/add_activity_count.php", {count: activities_count}, 3, 10).try(:body).to_s
        					ActiveRecord::Base.logger.info "Start job response: #{start_job_response}"
        				end
              end
      			end
      		end
      		# every hour prepare assign recovery phones
      		if bot_server.recovery_phone_assign_enabled
      			EmailAccount.prepare_assign_recovery_phone(bot_server, bot_server.accounts_assign_recovery_phone_per_day_per_phone)
      		end
        end
      end
      activities_count
    end
	end

	def self.average_online_time
		query = "SELECT AVG(google_account_activities.total_online_time / CEIL(ABS(DATE_PART('EPOCH',(TIMEZONE('UTC', CURRENT_TIMESTAMP) - google_account_activities.start_online_at))) / 86400))::integer AS average_online_time
		FROM google_account_activities
		LEFT OUTER JOIN google_accounts ON google_accounts.id = google_account_activities.google_account_id LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id AND email_accounts.email_item_type = 'GoogleAccount'
		WHERE email_accounts.is_active = true AND google_account_activities.total_online_time IS NOT NULL AND CEIL(ABS(DATE_PART('EPOCH',(TIMEZONE('UTC', CURRENT_TIMESTAMP) - google_account_activities.start_online_at))) / 86400) > 0;"
		result = ActiveRecord::Base.connection.execute(query).first['average_online_time'].to_s.to_i
	end

	def self.today_average_online_time
		query = "SELECT AVG(google_account_activities.today_online_time) AS today_average_online_time
		FROM google_account_activities
		LEFT OUTER JOIN google_accounts ON google_accounts.id = google_account_activities.google_account_id LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id AND email_accounts.email_item_type = 'GoogleAccount'
		WHERE email_accounts.is_active = true AND google_account_activities.today_online_time IS NOT NULL AND google_account_activities.today_online_time > 0;"
		result = ActiveRecord::Base.connection.execute(query).first['today_average_online_time'].to_s.to_i
	end

	def self.recovery_answers_checker
    if Rails.env.production?
      bot_servers = if Setting.get_value_by_name("GoogleAccountActivity::LOAD_BALANCING_ENABLED") == false.to_s
        BotServer.where(path: Setting.get_value_by_name("EmailAccount::BOT_URL"))
      else
        BotServer.where(human_emulation: true)
      end
      bot_servers.each do |bot_server|
    		if bot_server.recovery_answers_checker_enabled
    			now = Time.now.in_time_zone('Eastern Time (US & Canada)')
    			if Utils.open_for_business?(false, now, bot_server) && now.hour == bot_server.start_business_working_hour
    				ActiveRecord::Base.logger.info "Kill checker queue response : #{Time.now}"
    				kill_checker_queue_response = Utils.http_get("#{Setting.get_value_by_name("EmailAccount::ACCOUNT_CREATION_BOT_URL")}/recovery_answers_checker_null.php", {}, 3, 10).try(:body).to_s
    				ActiveRecord::Base.logger.info "#{kill_checker_queue_response}"
            sleep 5
    			end
    			date_from = Setting.find_by_name('GoogleAccountActivity::RECOVERY_BOT_RUNNING_STATUS').updated_at.getgm
    			activities_count = GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]])
            .where("email_accounts.is_active = false AND email_accounts.deleted IS NOT TRUE
              AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value}
              AND ((google_account_activities.recovery_answer_date[array_length(google_account_activities.recovery_answer_date, 1)] > ?
              AND google_account_activities.recovery_answer[array_length(google_account_activities.recovery_answer, 1)] in (?)) OR (google_account_activities.recovery_attempt[array_length(google_account_activities.recovery_attempt, 1)] > ? AND google_account_activities.recovery_answer_date[array_length(google_account_activities.recovery_answer_date, 1)] < ?))", date_from.getgm, [GoogleAccountActivity::RECOVERY_ANSWERS["No answer"], GoogleAccountActivity::RECOVERY_ANSWERS["Wait for the result"], GoogleAccountActivity::RECOVERY_ANSWERS["Authentification failed"]], date_from.getgm, date_from.getgm)
            .references(google_account:[email_account:[:bot_server]]).size
    			if activities_count > 0
    				ActiveRecord::Base.logger.info "Activities with recovery answers checker run time : #{Time.now}"
    				start_job_response = Utils.http_get("#{Setting.get_value_by_name("EmailAccount::ACCOUNT_CREATION_BOT_URL")}/recovery_answers_checker.php", {}, 3, 10).try(:body).to_s
    				ActiveRecord::Base.logger.info "Start job response: #{start_job_response}"
    			end
    		end
      end
    end
	end
end
