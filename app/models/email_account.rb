require 'csv'
class EmailAccount < ActiveRecord::Base
  include Reversible
  BOT_URL = "http://194.31.42.69"
  ACCOUNT_CREATION_BOT_URL = "http://192.99.120.164"
  OTHER_SCREENSHOT_PATH = "/out/login-scr/<email>.jpg"
  SIGN_IN_SCREENSHOT_PATH = "/out/login-scr/signin/<email>.jpg"
  RECOVERY_PHONE_ASSIGN_SCREENSHOT_PATH = "/out/login-scr/recphone/<email>.jpg"
  RECOVERY_ATTEMPT_SCREENSHOT_PATH = "/out/login-scr/recovery_attempt/<email>.jpg"
  REGISTRATION_SCREENSHOT_PATH = "/out/login-scr/registration/<email>.jpg"
  GMAIL_ACCOUNTS_PER_PHONE = 2
  PROFILE_COOKIE_FILE_PATH = "/out/cache/profiles/<username>/profilecookie.zpcookie"
  USER_AGENT_FILE_PATH = "/out/cache/profiles/<username>/useragent.txt"
	LAST_ORDER_ACCOUNT_TYPE = "1"
	LAST_ORDER_ACCOUNTS_NUMBER = "0"
	SYSTEM_TYPE_COUNTRY_CODE = "MD"
  NEW_DISABLED_ACCOUNTS_ALERT = 2
  belongs_to :email_item, polymorphic: true
  belongs_to :client
  belongs_to :email_accounts_setup
  belongs_to :locality, class_name: 'Geobase::Locality'
  belongs_to :region, class_name: 'Geobase::Region'
  belongs_to :recovery_phone, class_name: 'Phone'
  belongs_to :ip_address
  belongs_to :bot_server

  has_many :email_account_api_applications
  has_many :api_applications, through: :email_account_api_applications
  has_many :screenshots, as: :screenshotable, dependent: :destroy
  has_many :phone_usages, :as => :phone_usageable
  has_many :recovery_inbox_emails, dependent: :destroy

  before_save :change_status_date

  GENDERS = {male: true, female: false}
  ACCOUNT_TYPES = {operational: 1, system: 2}
  extend Enumerize
  enumerize :account_type, in: ACCOUNT_TYPES
  enumerize :gender, in: GENDERS

  accepts_nested_attributes_for :email_item
  validates :email, presence: true

  attr_accessor :user_agent, :profile_cookie

  has_attached_file :user_agent, path: ':rails_root/public/system/email_accounts/:id/cache/useragent.txt', url: '/system/email_accounts/:id/cache/useragent.txt'
  has_attached_file :profile_cookie, path: ':rails_root/public/system/email_accounts/:id/cache/profilecookie.zpcookie', url:  '/system/email_accounts/:id/cache/profilecookie.zpcookie'
  validates_attachment :user_agent, :profile_cookie, content_type: { content_type: ['text/plain','application/octet-stream'] }, size: { greater_than: 0.bytes, less_than: 100.megabytes }

  def email_with_locality
    str = self.id.to_s << " | "<< self.email
    str << " | " << self.locality.name if self.locality
    str << " | " << self.client.name if self.client
    str
  end

  def full_name
    [ firstname, lastname ].compact.join(' ')
  end

	def location
		if locality
			locality
		elsif region
			region
		end
	end

  def save_screenshot(screenshot_path, after_creation = false, removable = true)
    removable = false if after_creation
    bot_server_url = if after_creation
      Setting.get_value_by_name('EmailAccount::ACCOUNT_CREATION_BOT_URL')
    else
      self.bot_server.try(:path) || Setting.get_value_by_name('EmailAccount::BOT_URL')
    end
    username = self.email.strip.gsub("@gmail.com", "")
    image_url = bot_server_url + screenshot_path.gsub("<email>", username).downcase
    begin
      file = open(image_url)
      screen = Screenshot.new
      screen.image = file
      extension = Rack::Mime::MIME_TYPES.invert[screen.image_content_type]
      screen.image_file_name = File.basename(username)[0..-1] + extension
      screen.removable = removable
      self.screenshots << screen
      file.close unless file.closed?
      if screenshot_path == Setting.get_value_by_name("EmailAccount::REGISTRATION_SCREENSHOT_PATH")
        %x(curl -X GET "#{bot_server_url}/screen_rotate.php?path=registration&file=#{username}")
      end
      if screenshot_path == Setting.get_value_by_name("EmailAccount::SIGN_IN_SCREENSHOT_PATH")
        %x(curl -X GET "#{bot_server_url}/screen_rotate.php?path=signin&file=#{username}")
      end
      if screenshot_path == Setting.get_value_by_name("EmailAccount::OTHER_SCREENSHOT_PATH")
        %x(curl -X GET "#{bot_server_url}/screen_rotate.php?path=error&file=#{username}")
      end
      if screenshot_path == Setting.get_value_by_name("EmailAccount::RECOVERY_PHONE_ASSIGN_SCREENSHOT_PATH")
        %x(curl -X GET "#{bot_server_url}/screen_rotate.php?path=recphone&file=#{username}")
      end
      if screenshot_path == Setting.get_value_by_name("EmailAccount::RECOVERY_ATTEMPT_SCREENSHOT_PATH")
        %x(curl -X GET "#{bot_server_url}/screen_rotate.php?path=recovery_attempt&file=#{username}")
      end
      true
    rescue
      false
    end
  end

  def save_profile_cache(bot_path)
    profile_cookie_saved, user_agent_saved = false
    username = self.email.strip.gsub("@gmail.com", "")
    profile_cookie_url = bot_path + Setting.get_value_by_name("EmailAccount::PROFILE_COOKIE_FILE_PATH").gsub("<username>", username).downcase
    user_agent_url = bot_path + Setting.get_value_by_name("EmailAccount::USER_AGENT_FILE_PATH").gsub("<username>", username).downcase
    begin
      profile_cookie_file = open(profile_cookie_url)
      if profile_cookie_file && profile_cookie_file.size > 0
        self.profile_cookie = profile_cookie_file
        if self.save
          profile_cookie_saved = true
        end
      end
    rescue Exception => e
      ActiveRecord::Base.logger.error "Error while grabing profile cookie: #{e}"
    end
    unless self.user_agent.present?
      begin
        user_agent_file = open(user_agent_url)
        if user_agent_file && user_agent_file.size > 0
          self.user_agent = user_agent_file
          if self.save
            user_agent_saved = true
          end
        end
      rescue Exception => e
        ActiveRecord::Base.logger.error "Error while grabing user agent: #{e}"
      end
    end
    if profile_cookie_saved && user_agent_saved
      ActiveRecord::Base.logger.info "Profile cookie and user agent successfully saved"
    end
  end

  def assign_recovery_phone(phone)
    if recovery_phone_assigned.nil?
      gmail_accounts_limit = Setting.get_value_by_name("EmailAccount::GMAIL_ACCOUNTS_PER_PHONE").to_i
      assigns = EmailAccount.where(recovery_phone_id: phone.id).size
      phone = nil unless assigns < gmail_accounts_limit
      if phone.present?
        self.recovery_phone_id = phone.id
        self.recovery_phone_assigned = false
        self.save
      end
    end
  end

  class << self

    def recovery_email_domains
      sql_string = "SELECT distinct regexp_replace(recovery_email, '^.*@', '') as domains FROM public.email_accounts where account_type = 1 AND actual IS TRUE"
      ActiveRecord::Base.connection.execute(sql_string).to_a.map{|e| e["domains"]}.compact.sort
    end

    def prepare_assign_recovery_phone(bot_server, accounts_per_phone_per_day)
      available_phones = Phone.where("phone_provider_id = ? AND (last_assigned_at <= ? OR last_assigned_at IS NULL)", PhoneProvider.find_by_name('voip-ms').id, Time.now - Setting.get_value_by_name("GoogleAccountActivity::RECOVERY_PHONE_ASSIGN_DAYS_INTERVAL").to_i.days).order("(CASE WHEN last_assigned_at IS NULL THEN 1 ELSE 0 END) DESC, last_assigned_at ASC")
      available_phones.each do |phone|
        assigns_in_progress_size = EmailAccount.where("recovery_phone_id = ? AND recovery_phone_assigned IS NOT TRUE", phone.id).size
        if assigns_in_progress_size == 0
          google_accounts = GoogleAccount.includes(email_account:[:bot_server])
          .joins(:youtube_channels)
          .where("email_accounts.client_id IS NULL AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value} AND email_accounts.is_active = TRUE
          AND email_accounts.recovery_phone_id IS NULL AND email_accounts.recovery_phone_assigned IS NULL AND email_accounts.deleted IS NOT TRUE
          AND youtube_channels.id IS NOT NULL AND youtube_channels.channel_type = ? AND youtube_channels.is_active = TRUE AND bot_servers.id = ?", YoutubeChannel.channel_type.find_value(:personal).value, bot_server.id)
          .order("email_accounts.created_at asc").uniq
          count = 0
          google_accounts.each do |ga|
            if ga.youtube_channels.size == 1
              ga.email_account.assign_recovery_phone(phone)
              count += 1
            end
            break if count == accounts_per_phone_per_day
          end
        end
      end
    end

    def import_gmail_accounts
      GoogleAccount.all.each do |ga|
        self.import_gmail_account(ga)
      end
    end

    def by_id(id)
      return all unless id.present?
      where("email_accounts.id in (?)", id.strip.split(",").map(&:to_i))
    end

    def by_google_account_activity_id(google_account_activity_id)
      return all unless google_account_activity_id.present?
      where("google_account_activities.id = ?", google_account_activity_id.strip)
    end

    def by_email(email)
      return all unless email.present?
      where("lower(email_accounts.email) like ?", "%#{email.downcase}%")
    end

    def by_recovery_email_domain(recovery_email_domain)
      return all unless recovery_email_domain.present?
      where("lower(email_accounts.recovery_email) like ?", "%#{recovery_email_domain.downcase}%")
    end

    def by_ip(ip)
      return all unless ip.present?
      ip.gsub!('GoogleBanned', '') if ip != 'GoogleBanned'
      where("ip_addresses.address like ?", "%#{ip}%")
    end

    def by_account_type(account_type)
      return all unless account_type.present?
      where("email_accounts.account_type = ?", account_type)
    end

    def by_email_item_type(email_item_type)
      return all unless email_item_type.present?
      where("email_accounts.email_item_type = ?", email_item_type)
    end

    def by_tier(tier)
      return all unless tier.present?
      from = 0
      to = 2499
      case tier.to_i
        when 1
          return where("geobase_localities.population > 500000")
        when 2
          from = 100000
          to = 500000
        when 3
          from = 50000
          to = 99999
        when 4
          from = 25000
          to = 49999
        when 5
          from = 10000
          to = 24999
        when 6
          from = 5000
          to = 9999
        when 7
          from = 2500
          to = 4999
        end
      where("geobase_localities.population BETWEEN ? AND ?", from, to)
    end

    def by_country_id(country_id)
      return all unless country_id.present?
      where("geobase_regions.country_id = ?", country_id)
    end

    def by_region_id(region_id)
      return all unless region_id.present?
      where("geobase_localities.primary_region_id = ? OR geobase_regions.id = ? OR email_accounts.region_id = ?", region_id, region_id, region_id)
    end

    def by_locality_id(locality_id)
      return all unless locality_id.present?
      where("geobase_localities.id = ?", locality_id)
    end

    def by_is_active(active)
      return all unless active.present?
      if active == true.to_s
        where("email_accounts.is_active = true")
      else
        where("email_accounts.is_active IS NOT TRUE")
      end
    end

    def by_assigned_to_client(assigned)
      return all unless assigned.present?
      if assigned == true.to_s
        where("email_accounts.client_id IS NOT NULL")
      else
        where("email_accounts.client_id IS NULL")
      end
    end

    def by_deleted(deleted)
      return all unless deleted.present?
      if deleted == true.to_s
        where("email_accounts.deleted = true")
      else
        where("email_accounts.deleted IS NOT TRUE")
      end
    end

    def by_lost(lost)
      return all unless lost.present?
      if lost == true.to_s
        where("email_accounts.deleted = true
          AND (google_account_activities.recovery_answer[array_length(google_account_activities.recovery_answer, 1)] IS NULL
          OR google_account_activities.recovery_answer[array_length(google_account_activities.recovery_answer, 1)] <> ?)", GoogleAccountActivity::RECOVERY_ANSWERS["Deleted account"])
      else
        where("email_accounts.deleted = true
          AND google_account_activities.recovery_answer[array_length(google_account_activities.recovery_answer, 1)] = ?", GoogleAccountActivity::RECOVERY_ANSWERS["Deleted account"])
      end
    end

    def by_error_type(error_type)
      return all unless error_type.present?
      where("(google_accounts.error_type = ?)", error_type)
    end

    def by_is_verified_by_phone(is_verified_by_phone)
      return all unless is_verified_by_phone.present?
      if is_verified_by_phone == true.to_s
        where("email_accounts.is_verified_by_phone = true")
      else
        where("email_accounts.is_verified_by_phone IS NOT TRUE")
      end
    end

    def by_client_id(client_id)
      return all unless client_id.present?
      where("email_accounts.client_id = ?", client_id)
    end

    def by_bot_server_id(bot_server_id)
      return all unless bot_server_id.present?
      where("email_accounts.bot_server_id = ?", bot_server_id)
    end

    def by_recovery_answer(recovery_answer, recovery_answer_date_from)
      return all unless recovery_answer.present?
      if recovery_answer_date_from.present?
        if recovery_answer_date_from.to_s == "0" && recovery_answer.to_s == "0"
          where("google_account_activities.recovery_attempt[array_length(google_account_activities.recovery_attempt, 1)] < ? OR google_account_activities.recovery_attempt[array_length(google_account_activities.recovery_attempt, 1)] IS NULL", (Time.now - 24.hours).getgm)
        else
          where("google_account_activities.recovery_answer[array_length(google_account_activities.recovery_answer, 1)] = ?
            AND google_account_activities.recovery_answer_date[array_length(google_account_activities.recovery_answer_date, 1)] > ?", recovery_answer, recovery_answer_date_from.to_time)
        end
      else
        where("google_account_activities.recovery_answer[array_length(google_account_activities.recovery_answer, 1)] = ?", recovery_answer)
      end
    end

    def by_display_all(display_all)
      if display_all.present?
        return all
      else
        where("email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value}")
      end
    end

    def by_recovery_phone_assigned(recovery_phone_assigned)
      return all unless recovery_phone_assigned.present?
      if recovery_phone_assigned == true.to_s
        where("email_accounts.recovery_phone_assigned = true")
      elsif recovery_phone_assigned == false.to_s
        where("email_accounts.recovery_phone_assigned = false")
      elsif recovery_phone_assigned == "suspended"
        where("email_accounts.recovery_phone_id IS NOT NULL AND email_accounts.recovery_phone_assigned IS NULL")
      else
        where("email_accounts.recovery_phone_assigned IS NULL")
      end
    end

    def by_has_alternate_email(has_alternate_email)
      return all unless has_alternate_email.present?
      if has_alternate_email == true.to_s
        where("google_accounts.alternate_email IS NOT NULL AND google_accounts.alternate_email <> ''")
      else
        where("google_accounts.alternate_email IS NULL OR google_accounts.alternate_email = ''")
      end
    end

    def by_has_recovery_email(has_recovery_email)
      return all unless has_recovery_email.present?
      if has_recovery_email == true.to_s
        where("array_length(google_account_activities.recovery_email, 1) > 0")
      else
        where("google_account_activities.recovery_email = '{}'")
      end
    end

    def by_recovery_email_sync(recovery_email_sync)
      return all unless recovery_email_sync.present?
      if recovery_email_sync == true.to_s
        where("email_accounts.recovery_email_sync = true")
      else
        where("email_accounts.recovery_email_sync IS NOT TRUE")
      end
    end

    def by_last_event_time(table_name, field_name, last_time)
      return all if !(last_time.present? && field_name.present? && table_name.present?)
      where("#{table_name}.#{field_name} between ? AND current_timestamp", Time.now - last_time.to_i.hours)
    end

    def by_recovery_inbox_email_type(email_type)
      return all unless email_type.present?
      where("recovery_inbox_emails.email_type = ?", email_type)
    end

    def update_profiles_cache
      bot_servers = if Setting.get_value_by_name("GoogleAccountActivity::LOAD_BALANCING_ENABLED") == false.to_s
        BotServer.where(path: Setting.get_value_by_name("EmailAccount::BOT_URL"))
      else
        BotServer.where(human_emulation: true)
      end
      bot_servers.each do |bot_server|
        email_accounts = EmailAccount.includes(:bot_server).by_account_type(EmailAccount.account_type.find_value(:operational).value).where("actual IS TRUE AND bot_servers.id = ?", bot_server.id).references(:bot_server)
        email_accounts.each do |ea|
          ea.delay(queue: DelayedJobQueue::SAVE_PROFILE_CACHE, priority: 1).save_profile_cache(bot_server.path)
        end
      end
    end
  end

  private
    def change_status_date
      if self.id.present? && (self.is_active_changed? || self.deleted_changed?)
        now = Time.now
        self.status_change_date = now
        self.last_disabled_at = now if !self.is_active
        if self.is_active_changed? && !self.is_active
          disabled_count = EmailAccount.by_display_all(nil).by_account_type(EmailAccount.account_type.find_value(:operational).value).by_deleted(false.to_s).by_is_active(false.to_s).where("status_change_date > ?", Time.now - 24.hours).size + 1
          if disabled_count >= Setting.get_value_by_name("EmailAccount::NEW_DISABLED_ACCOUNTS_ALERT").to_i && Rails.env.production?
            BotServer.kill_all_zenno
            Utils.pushbullet_broadcast("New blocked gmail accounts!", "For last 24 hours were blocked #{disabled_count} gmail accounts. All bot servers were killed and disabled daily activity: #{Rails.configuration.routes_default_url_options[:host]}#{Rails.application.routes.url_helpers.email_accounts_path(account_type: 1, is_active: false, status_changed_last_time: 24)}")
            BroadcasterMailer.new_blocked_gmail_accounts
          end
        end
      end
    end

    def self.import_gmail_account(ga)
      unless EmailAccount.where('LOWER(email) = ?', ga.email.to_s.downcase).exists?
        EmailAccount.create(email: ga.email,
          password: ga.password,
          firstname: ga.first_name,
          lastname: ga.last_name,
          birth_date: ga.birth_date,
          locality_id: ga.locality_id,
          region_name: ga.state,
          locality_name: ga.city,
          recovery_email: ga.recovery_email,
          recovery_email_password: ga.password,
          email_item_id: ga.id,
          email_item_type: 'GoogleAccount')
      end
    end
end
