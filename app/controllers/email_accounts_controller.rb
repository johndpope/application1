require 'csv'
class EmailAccountsController < ApplicationController
  ActionController::Parameters.permit_all_parameters = true
  skip_before_filter :authenticate_admin_user!, :only => [:save_screenshot]
  skip_before_filter :verify_authenticity_token, :only => [:save_screenshot]
  before_action :set_email_account, only: [:save_screenshot]
  EMAIL_ACCOUNT_DEFAULT_LIMIT = 25
  ACCOUNT_PROGRESS_STEPS = {
    "1-1" => { step: 1, value: "Data generation" },
    "1-2" => { step: 2, value: "Filling form(username/password)" },
    "1-3" => { step: 3, value: "Filling form(Personal data)" },
    "1-4" => { step: 4, value: "Filling form(Recovery email)" },
    "1-5" => { step: 5, value: "Capcha recognition" },
    "1-6" => { step: 6, value: "Sending data to Google" },
    "2-1" => { step: 7, value: "Getting phone number(Gmail)" },
    "2-2" => { step: 8, value: "Checking if phone number is valid(Gmail)" },
    "2-3" => { step: 9, value: "Fiilling form(SMS - Gmail)" },
    "100" => { step: 10, value: "Create Account" }
  }

  def edit
    @activity_columns = GoogleAccountActivity.column_names - %w(id google_account_id linked recovery_answer last_recovery_email_inbox_mail_date updated_at created_at total_online_time start_online_at)
    @activity_columns.sort!
    @email_account = EmailAccount.find(params[:id])
    if @email_account.email_item_type == "GoogleAccount"
      if @email_account.email_item.google_account_activity.nil?
        @email_account.email_item.google_account_activity = GoogleAccountActivity.create(google_account_id: @email_account.email_item.id)
      end
      @adwords_campaigns = @email_account.email_item.adwords_campaigns
      gaa = @email_account.email_item.google_account_activity
      params[:activity] = []
      #fields = %w(alternate_email locality background)
      fields = %w()
      fields.each do |field|
        params[:activity] << field if gaa.read_attribute(field).nil?
      end
    end
  end

  def update
    @email_account = EmailAccount.find(params[:id])
    if @email_account.update_attributes(email_account_params)
      render json: {
        status: 200,
        updated_at: (render_to_string partial: "updated_at_time", locals: { email_account: @email_account, field: :updated_at }, layout: false),
        status_change_date: (render_to_string partial: "updated_at_time", locals: { email_account: @email_account, field: :status_change_date }, layout: false),
        last_disabled_at: (render_to_string partial: "updated_at_time", locals: { email_account: @email_account, field: :last_disabled_at }, layout: false)
      }
    else
      render json: {status: 500}
    end
  end

  def index
    if params[:filter].present?
      unless params[:filter][:order].present?
        params[:filter][:order] = "created_at"
      end
      unless params[:filter][:order_type].present?
        params[:filter][:order_type] = "asc"
      end
    else
      params[:filter] = {order: "created_at", order_type: "desc" }
    end
    params[:email].strip! if params[:email].present?
    params[:ip].strip! if params[:ip].present?
    params[:account_type] = EmailAccount.account_type.find_value(:operational).value unless params[:account_type].present?
    params[:limit] = EMAIL_ACCOUNT_DEFAULT_LIMIT unless params[:limit].present?
    nulls_last = " NULLS LAST"
    order_by = "email_accounts."
    unless %w{id email account_type is_active deleted is_verified_by_phone recovery_email_sync ip client activity_start activity_end activity_end_crash
      last_success_sign_in check_status_start check_status activity_time recovery_time today_online_time recovery_answer status_change_date created_at}.include?(params[:filter][:order])
      if params[:filter][:order] == "tier"
        order_by = "geobase_localities.population"
      else
        order_by =  "geobase_" + params[:filter][:order].pluralize + ".name"
      end
    else
      if params[:filter][:order] == "client"
        order_by = "clients.name"
      elsif %w(activity_start activity_end activity_end_crash last_success_sign_in check_status_start check_status).include?(params[:filter][:order])
        order_by = "google_account_activities.#{params[:filter][:order]}[array_length(google_account_activities.#{params[:filter][:order]}, 1)]"
      elsif params[:filter][:order] == "recovery_answer"
        order_by = "google_account_activities.recovery_answer"
      elsif params[:filter][:order] == "activity_time"
        order_by =
        "case
          when activity_end[array_length(activity_end, 1)] - activity_start[array_length(activity_start, 1)] > '00:00:00'
            then 3
          when activity_end_crash[array_length(activity_end_crash, 1)] - activity_start[array_length(activity_start, 1)] > '00:00:00'
            then 3
          else null
          end,
        case
          when activity_end[array_length(activity_end, 1)] - activity_start[array_length(activity_start, 1)] > '00:00:00'
            then activity_end[array_length(activity_end, 1)] - activity_start[array_length(activity_start, 1)]
          when activity_end_crash[array_length(activity_end_crash, 1)] - activity_start[array_length(activity_start, 1)] > '00:00:00'
            then activity_end_crash[array_length(activity_end_crash, 1)] - activity_start[array_length(activity_start, 1)]
          when activity_end[array_length(activity_end, 1)] - activity_start[array_length(activity_start, 1)] < '00:00:00'
            then activity_end[array_length(activity_end, 1)] - activity_start[array_length(activity_start, 1)]
          when activity_end_crash[array_length(activity_end_crash, 1)] - activity_start[array_length(activity_start, 1)] < '00:00:00'
            then activity_end_crash[array_length(activity_end_crash, 1)] - activity_start[array_length(activity_start, 1)]
          else null
          end"
      elsif params[:filter][:order] == "recovery_time"
        order_by =
        "case
          when recovery_attempt[array_length(recovery_attempt, 1)] - recovery_attempt_start[array_length(recovery_attempt_start, 1)] > '00:00:00'
            then 3
          when recovery_attempt_crash[array_length(recovery_attempt_crash, 1)] - recovery_attempt_start[array_length(recovery_attempt_start, 1)] > '00:00:00'
            then 3
          else null
          end,
        case
          when recovery_attempt[array_length(recovery_attempt, 1)] - recovery_attempt_start[array_length(recovery_attempt_start, 1)] > '00:00:00'
            then recovery_attempt[array_length(recovery_attempt, 1)] - recovery_attempt_start[array_length(recovery_attempt_start, 1)]
          when recovery_attempt_crash[array_length(recovery_attempt_crash, 1)] - recovery_attempt_start[array_length(recovery_attempt_start, 1)] > '00:00:00'
            then recovery_attempt_crash[array_length(recovery_attempt_crash, 1)] - recovery_attempt_start[array_length(recovery_attempt_start, 1)]
          when recovery_attempt[array_length(recovery_attempt, 1)] - recovery_attempt_start[array_length(recovery_attempt_start, 1)] < '00:00:00'
            then recovery_attempt[array_length(recovery_attempt, 1)] - recovery_attempt_start[array_length(recovery_attempt_start, 1)]
          when recovery_attempt_crash[array_length(recovery_attempt_crash, 1)] - recovery_attempt_start[array_length(recovery_attempt_start, 1)] < '00:00:00'
            then recovery_attempt_crash[array_length(recovery_attempt_crash, 1)] - recovery_attempt_start[array_length(recovery_attempt_start, 1)]
          else null
          end"
      elsif params[:filter][:order] == "today_online_time"
        order_by = "google_account_activities.today_online_time"
      elsif params[:filter][:order] == "ip"
        order_by = "ip_addresses.address"
      else
        order_by += params[:filter][:order]
      end
      nulls_last = "" if %w{is_active is_verified_by_phone deleted recovery_email_sync}.include?(params[:filter][:order])
    end
    column_names = EmailAccount.column_names
    column_names_string = "email_accounts." + column_names.join(",email_accounts.")
    @email_accounts = EmailAccount.unscoped.distinct.select("#{column_names_string}, #{order_by}")
      .joins('LEFT OUTER JOIN geobase_localities ON geobase_localities.id = email_accounts.locality_id
        LEFT OUTER JOIN geobase_regions ON geobase_regions.id = geobase_localities.primary_region_id
        LEFT OUTER JOIN geobase_countries ON geobase_countries.id = geobase_regions.country_id
        LEFT OUTER JOIN clients ON clients.id = email_accounts.client_id
        LEFT OUTER JOIN geobase_regions as gr ON gr.id = email_accounts.region_id
        LEFT OUTER JOIN ip_addresses ON ip_addresses.id = email_accounts.ip_address_id
        LEFT OUTER JOIN google_accounts ON email_accounts.email_item_id = google_accounts.id
        LEFT OUTER JOIN google_account_activities ON google_accounts.id = google_account_activities.google_account_id
        LEFT JOIN recovery_inbox_emails ON recovery_inbox_emails.email_account_id = email_accounts.id')
      .by_display_all(params[:display_all])
      .by_id(params[:id])
      .by_ip(params[:ip])
      .by_email(params[:email])
      .by_recovery_email_domain(params[:recovery_email_domain])
      .by_email_item_type(params[:email_item_type])
      .by_account_type(params[:account_type])
      .by_tier(params[:tier])
      .by_locality_id(params[:locality_id])
      .by_region_id(params[:region_id])
      .by_is_active(params[:is_active])
      .by_deleted(params[:deleted])
      .by_lost(params[:lost])
      .by_recovery_email_sync(params[:recovery_email_sync])
      .by_assigned_to_client(params[:assigned_to_client])
      .by_recovery_phone_assigned(params[:recovery_phone_assigned])
      .by_is_verified_by_phone(params[:is_verified_by_phone])
      .by_error_type(params[:error_type])
      .by_client_id(params[:client_id])
      .by_bot_server_id(params[:bot_server_id])
      .by_recovery_answer(params[:recovery_answer], params[:recovery_answer_date_from])
      .by_has_recovery_email(params[:has_recovery_email])
      .by_has_alternate_email(params[:has_alternate_email])
      .by_google_account_activity_id(params[:google_account_activity_id])
      .by_last_event_time("recovery_inbox_emails", "date", params[:recovery_inbox_email_last_time])
      .by_last_event_time("email_accounts", "status_change_date", params[:status_changed_last_time])
      .by_recovery_inbox_email_type(params[:recovery_inbox_email_type])
      .page(params[:page]).per(params[:limit])
      .order(order_by + " " + params[:filter][:order_type] + nulls_last)
    @email_item_types = []
    EmailAccount.distinct.where("email_item_type IS NOT NULL").pluck(:email_item_type).each do |eitype|
      @email_item_types << [eitype.tableize.humanize.titleize.singularize, eitype]
    end
    respond_to do |format|
      format.html
      format.json {
        json_text = []
        @email_accounts.each do |ea|
          json_object = {}
          json_object[:id] = ea.email_item.try(:google_account_activity).try(:id)
          json_object[:email_account_id] = ea.id
          json_object[:email] = ea.email
          json_object[:password] = ea.password
          json_object[:ip] = ea.ip_address.try(:address)
          json_text << json_object
        end
        render :json => json_text.to_json
      }
    end
  end

  def legend
    @email_account = EmailAccount.find(params[:id])
    respond_to do |format|
      format.html { render 'legend', layout: false, locals: { email_account: @email_account } }
    end
  end

  def order
  end

  def execute_accounts_order
    account_type = params[:account_type]
    accounts_number = params[:accounts_number]
    Setting.get_value_by_name("EmailAccount::LAST_ORDER_ACCOUNT_TYPE")
    Setting.get_value_by_name("EmailAccount::LAST_ORDER_ACCOUNTS_NUMBER")
    account_type_setting = Setting.find_by_name("EmailAccount::LAST_ORDER_ACCOUNT_TYPE")
    account_type_setting.value = account_type
    account_type_setting.save
    accounts_number_setting = Setting.find_by_name("EmailAccount::LAST_ORDER_ACCOUNTS_NUMBER")
    accounts_number_setting.value = accounts_number
    accounts_number_setting.save
    accounts_number_setting.touch
    order_accounts_response = if Rails.env.production?
      Utils.http_get("#{Setting.get_value_by_name("EmailAccount::ACCOUNT_CREATION_BOT_URL")}/addcount.php", {count: accounts_number}, 3, 10).try(:body).to_s
    else
      "Doesn't launch on development"
    end
    ActiveRecord::Base.logger.info "Account creation response: #{order_accounts_response}"
    respond_to do |format|
      format.html { redirect_to dashboard_path, notice: "Order was successfully sent to account creation bot. Response message: #{order_accounts_response}. Please watch progress bar on dashboard." }
    end
  end

  def create_gmail_account
    params.each { |key, value| value.strip! }
    ip_path = params[:bot_server_ip].present? ? "http://" + params[:bot_server_ip] : Setting.get_value_by_name("EmailAccount::ACCOUNT_CREATION_BOT_URL")
    bot_server = BotServer.find_by_path(ip_path) || BotServer.find_by_path(Setting.get_value_by_name("EmailAccount::BOT_URL"))
    now = Time.now
    response = if params[:email].present? && params[:password].present?
      watching_video_categories = WatchingVideoCategory.all
      params[:birth_date] = params[:birth_date].present? ? DateTime.parse(params[:birth_date]) : nil
      params[:country_name] = "US"
      params[:is_active] = true
      params[:deleted] = false
      params[:true] = true
      params[:gender] = params[:gender].try(:downcase) == "true"
      params[:creation_source] = "Hackers program"
      params[:is_verified_by_phone] = params[:registration_phone_number].present?
      params[:recovery_phone_number] = params[:registration_phone_number]
      params[:account_type] = Setting.get_value_by_name("EmailAccount::LAST_ORDER_ACCOUNT_TYPE").to_i

      if params[:fail_reason].present? && params[:fail_reason].to_i > 0
        if AccountCreationFail.where("lower(email) = ?", params[:email].try(:downcase).try(:strip)).first.nil?
          acf = AccountCreationFail.create(email: params[:email], reason: params[:fail_reason], phone: params[:registration_phone_number],
            ip: params[:ip], user_agent: params[:user_agent_text])
          acf.update_attributes({created_at: now, updated_at: now})
        end
        "Account creation fail"
      else
        if EmailAccount.where("lower(email) = ?", params[:email].try(:downcase).try(:strip)).first.nil?
          params.delete(:created_at)
          email_account = EmailAccount.new
          email_account.attributes = params.reject{|k,v| !email_account.attributes.keys.member?(k.to_s) }
          ip_address = IpAddress.where("address = ?", params[:ip]).first
          if ip_address.present?
            email_account.ip_address = ip_address
            ip_address.last_assigned_at = now
            ip_address.save
          end
          phone = Phone.where("phone_provider_id = ? AND value = ?", PhoneProvider.find_by_name('voip-ms').id, params[:recovery_phone_number_assigned]).first
          if phone.present?
            email_account.recovery_phone = phone
            email_account.recovery_phone_assigned = true
            email_account.recovery_phone_assigned_at = now
            phone.last_assigned_at = now
            phone.save
          end
          email_account.save

          google_account = GoogleAccount.new
          google_account.attributes = params.reject{|k,v| !google_account.attributes.keys.member?(k.to_s) }
          google_account.save

          google_account.update_attributes({created_at: now, updated_at: now})

          email_account.email_item_type = GoogleAccount.name
          email_account.email_item_id = google_account.id
          bot_server = BotServer.find_by_path(Setting.get_value_by_name("EmailAccount::BOT_URL"))
          email_account.bot_server = bot_server
          email_account.actual = true
          email_account.save

          email_account.update_attributes({created_at: now, updated_at: now})

          gaa = GoogleAccountActivity.create(google_account_id: email_account.email_item.id)
          ['first_name','last_name', 'locality', 'region', 'country', 'birth_date', 'phone', 'open_emails', 'delete_emails', 'mark_as_read'].each do |field|
            gaa.touch(field, now.to_time)
          end
          gaa.watching_video_categories << watching_video_categories.sample(Setting.get_value_by_name("WatchingVideoCategory::WATCHING_VIDEO_CATEGORIES_NUMBER").to_i)
          gaa.update_attributes({created_at: now, updated_at: now})
          email_account.delay(queue: DelayedJobQueue::SAVE_PROFILE_CACHE, priority: 1, run_at: 1.minutes.from_now).save_profile_cache(ip_path)
          email_account.delay(queue: DelayedJobQueue::SAVE_SCREENSHOT, priority: 2).save_screenshot(Setting.get_value_by_name("EmailAccount::REGISTRATION_SCREENSHOT_PATH"), true)
          email_account.delay(queue: DelayedJobQueue::SAVE_SCREENSHOT, priority: 2).save_screenshot(Setting.get_value_by_name("EmailAccount::SIGN_IN_SCREENSHOT_PATH"), true)
          email_account.delay(queue: DelayedJobQueue::SAVE_SCREENSHOT, priority: 2).save_screenshot(Setting.get_value_by_name("EmailAccount::OTHER_SCREENSHOT_PATH"), true)
          email_account.delay(queue: DelayedJobQueue::SAVE_SCREENSHOT, priority: 2).save_screenshot(Setting.get_value_by_name("EmailAccount::RECOVERY_PHONE_ASSIGN_SCREENSHOT_PATH"), true)
          gaa.id
        else
          "Duplicate"
        end
      end
    else
      "Fail"
    end
    render json: response
  end

  def json_list
    @accounts = if params[:id].present?
      EmailAccount.includes(:locality).where("email_accounts.email_item_id = ?", params[:id]).references(:localities)
    else
      EmailAccount.includes(:locality).where("(CAST(email_accounts.id as text) LIKE ? OR LOWER(email_accounts.email) LIKE ? OR
        LOWER(geobase_localities.name) LIKE ?) AND email_item_type = 'GoogleAccount' AND email_accounts.is_active=true AND email_accounts.deleted IS NOT TRUE",
      "#{params[:q].strip}%", "%#{params[:q].strip.downcase}%", "%#{params[:q].strip.downcase}%").references(:localities)
    .order(:email)
    end
    render json: @accounts.map { |e| {id: e.email_item_id, text: "#{e.id} | #{e.email} #{' | ' + e.locality.try(:name) if e.locality}"} }
  end

  def save_screenshot
    status = if params[:file].present? && params[:file].try(:tempfile).present?
      username = @email_account.email.strip.gsub("@gmail.com", "")
      screen = Screenshot.new
      screen.image = params[:file].tempfile
      screen.action_type = params[:action_type].try(:strip)
      extension = Rack::Mime::MIME_TYPES.invert[screen.image_content_type]
      screen.image_file_name = File.basename(username)[0..-1] + extension
      screen.removable = true
      @email_account.screenshots << screen
      %x(rm -rf #{params[:file].tempfile.path})
      {status: 200}
    else
      {status: 500}
    end
    render json: status, status: status[:status]
  end

  private

		def set_email_account
			@email_account = EmailAccount.find(params[:id])
		end

    def email_account_params
      #temporary, need to fix
      params[:email_account][:birth_date] = DateTime.strptime(params[:email_account][:birth_date], '%m/%d/%Y') if params[:email_account][:birth_date].present?
      params.require(:email_account)
    end
end
