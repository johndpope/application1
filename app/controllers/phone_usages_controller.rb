class PhoneUsagesController < ApplicationController
  ActionController::Parameters.permit_all_parameters = true
  PHONE_USAGE_DEFAULT_LIMIT = 25
  def index
    params[:limit] = PHONE_USAGE_DEFAULT_LIMIT unless params[:limit].present?
    if params[:filter].present?
			unless params[:filter][:order].present?
				params[:filter][:order] = "created_at"
			end
			unless params[:filter][:order_type].present?
				params[:filter][:order_type] = "desc"
			end
		else
			params[:filter] = {order: "created_at", order_type: "desc" }
		end
    nulls_last = " NULLS LAST"
    order_by = "phone_usages."
    if %w(country).include?(params[:filter][:order])
			order_by =  "geobase_" + params[:filter][:order].pluralize + ".name"
		else
      if params[:filter][:order] == "phone_provider"
        order_by = "phone_providers.name"
      elsif params[:filter][:order] == "phone"
        order_by = "phones.value"
      elsif params[:filter][:order] == "phone_service"
        order_by = "phone_services.name"
      elsif params[:filter][:order] == "phone_service_account"
        order_by = "api_accounts.username"
      else
        order_by += params[:filter][:order]
      end
    end
    @phone_usages = PhoneUsage.includes({phone: [:country]}, :phone_provider, :phone_service, phone_service_account: [:api_account])
    .by_id(params[:id])
    .by_transaction_id(params[:transaction_id])
    .by_session_id(params[:session_id])
    .by_phone(params[:phone])
    .by_sms_code(params[:sms_code])
    .by_sms_code_presence(params[:sms_code_presence])
    .by_phone_provider_id(params[:phone_provider_id])
    .by_country_id(params[:country_id])
    .by_phone_service_id(params[:phone_service_id])
    .by_phone_service_account_id(params[:phone_service_account_id])
    .by_error_type(params[:error_type])
    .by_action_type(params[:action_type])
    .by_web_service_type(params[:web_service_type])
    .by_source_type(params[:source_type])
    .by_phone_usageable_id(params[:phone_usageable_id])
    .by_phone_usageable_type(params[:phone_usageable_type])
    .by_last_days(params[:last_days])
    .page(params[:page]).per(params[:limit])
    .order(order_by + " " + params[:filter][:order_type] + nulls_last)
    .references({phone: [:country]}, :phone_provider, :phone_service, phone_service_account: [:api_account])
    date_from = if params[:date_from].present?
      pattern_from = (params[:date_from].include? "-") ? "%Y-%m-%d" : "%m/%d/%Y"
      params[:date_from] = (DateTime.strptime(params[:date_from], pattern_from).to_time + 4.hours).in_time_zone('Eastern Time (US & Canada)')
    else
      params[:date_from] = Time.now.in_time_zone('Eastern Time (US & Canada)')
    end
    date_to = if params[:date_to].present?
      pattern_to = (params[:date_to].include? "-") ? "%Y-%m-%d" : "%m/%d/%Y"
      params[:date_to] = (DateTime.strptime(params[:date_to], pattern_to).to_time + 4.hours).in_time_zone('Eastern Time (US & Canada)')
    else
      params[:date_to] = Time.now.in_time_zone('Eastern Time (US & Canada)')
    end
    date_from = date_from - date_from.hour.hours - date_from.min.minutes - date_from.sec.seconds + 1.second
    date_to = (date_to - date_to.hour.hours - date_to.min.minutes - date_to.sec.seconds) + 24.hours - 1.second
    @success_attempts_size = PhoneUsage.where("error_type IS NULL AND created_at > ? AND created_at < ?", date_from.getgm, date_to.getgm).size
    @unsuccess_attempts_size = PhoneUsage.where("error_type IS NOT NULL AND created_at > ? AND created_at < ?", date_from.getgm, date_to.getgm).size
    unsuccess_providers_sql =
		"SELECT phone_providers.name as name, count(phone_usages.id) as count
    FROM phone_usages LEFT OUTER JOIN \"phone_providers\" ON \"phone_providers\".\"id\" = \"phone_usages\".\"phone_provider_id\"
    WHERE phone_usages.error_type IS NOT NULL AND phone_usages.created_at > '#{date_from.getgm}' AND phone_usages.created_at < '#{date_to.getgm}'
    GROUP BY phone_providers.name
    ORDER BY phone_providers.name;"
    success_providers_sql =
		"SELECT phone_providers.name as name, count(phone_usages.id) as count
    FROM phone_usages LEFT OUTER JOIN \"phone_providers\" ON \"phone_providers\".\"id\" = \"phone_usages\".\"phone_provider_id\"
    WHERE phone_usages.error_type IS NULL AND phone_usages.created_at > '#{date_from.getgm}' AND phone_usages.created_at < '#{date_to.getgm}'
    GROUP BY phone_providers.name
    ORDER BY phone_providers.name;"
    unsuccess_providers_and_errors_sql =
    "SELECT phone_providers.name as provider, phone_usages.error_type as error_type,count(phone_usages.id) as count
    FROM phone_usages LEFT OUTER JOIN \"phone_providers\" ON \"phone_providers\".\"id\" = \"phone_usages\".\"phone_provider_id\"
    WHERE phone_usages.error_type IS NOT NULL AND phone_usages.created_at > '#{date_from.getgm}' AND phone_usages.created_at < '#{date_to.getgm}'
    GROUP BY phone_providers.name, phone_usages.error_type
    ORDER BY phone_providers.name, phone_usages.error_type;"
    error_types_sql =
    "SELECT error_type, count(id) as count
    FROM phone_usages
    WHERE error_type IS NOT NULL AND created_at > '#{date_from.getgm}' AND created_at < '#{date_to.getgm}'
    GROUP BY error_type
    ORDER BY error_type;"
		@unsuccess_providers = ActiveRecord::Base.connection.execute(unsuccess_providers_sql)
    @success_providers = ActiveRecord::Base.connection.execute(success_providers_sql)
    @error_types = ActiveRecord::Base.connection.execute(error_types_sql)
    @unsuccess_providers_and_errors = ActiveRecord::Base.connection.execute(unsuccess_providers_and_errors_sql)
    @phone_usageable_types = []
		PhoneUsage.distinct.where("phone_usageable_type IS NOT NULL").pluck(:phone_usageable_type).each do |putype|
			@phone_usageable_types << [putype.tableize.humanize.titleize.singularize, putype]
		end
  end

	def last_sms_code
		phone_number = params[:phone_number].try(:strip)
		sms_code = if phone_number.present?
			phone_usage = PhoneUsage.includes(:phone)
			.where("phones.value = ? AND phone_usages.sms_code IS NOT NULL", phone_number)
			.order("phone_usages.created_at desc")
			.references(:phone).first
			(phone_usage.present? && phone_usage.sms_code.present?) ? phone_usage.sms_code : ""
		end
		response = if !sms_code.nil?
      {status: 200, sms_code: sms_code}
    else
      {status: 500, sms_code: ""}
    end
    render json: response, status: response[:status]
	end
end
