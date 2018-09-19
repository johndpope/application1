class PhoneUsage < ActiveRecord::Base
  belongs_to :phone_usageable, :polymorphic => true
  belongs_to :phone, foreign_key: :phone_id
  belongs_to :phone_service, foreign_key: :phone_service_id
  belongs_to :phone_provider, foreign_key: :phone_provider_id
  belongs_to :phone_service_account, foreign_key: :phone_service_account_id

  ERROR_TYPES = {"google did not accept provided phone"=>1, "google accepted provided phone, sms was not received"=>2,
    "no free numbers for selected gsm provider"=>3,"our bid is less that of activator"=>4,
    "other problem on activator part"=>5, "google accepted provided phone, sms was incorrect"=>6, "can't recognize digits"=>7, "too many variations"=>8, "no call"=>9, "facebook did not accept provided phone"=>10, "facebook accepted provided phone, sms was not received"=>11, "facebook accepted provided phone, sms was incorrect"=>12, "used too many times for verification"=>13, "this phone number cannot be used for verification"=>14}
  ACTION_TYPES = {"google account recovery"=>1, "youtube business channel creation"=>2, "google account creation"=>3,
		"google account recovery phone assign"=>4, "youtube business channel verification"=>5, "facebook account creation"=>6}
  WEB_SERVICE_TYPES = {"google"=>1, "facebook"=>2, "twitter"=>3}
  SOURCE_TYPES = {"call"=>1, "sms"=>2}

  extend Enumerize
  enumerize :error_type, :in=> ERROR_TYPES
  enumerize :action_type, :in=> ACTION_TYPES
  enumerize :web_service_type, :in=> WEB_SERVICE_TYPES
  enumerize :source_type, :in=> SOURCE_TYPES

  def call_file_url
    if self[:call_file_url].present?
      Setting.get_value_by_name("Phone::ASTERISK_URL") + self[:call_file_url]
    end
  end

  class << self
    def by_id(id)
			return all unless id.present?
			where("phone_usages.id = ?", id.strip)
		end

    def by_transaction_id(transaction_id)
      return all unless transaction_id.present?
      where("phone_usages.transaction_id = ?", transaction_id.strip)
    end

    def by_session_id(session_id)
      return all unless session_id.present?
      where("phone_usages.session_id = ?", session_id.strip)
    end

    def by_phone(phone)
      return all unless phone.present?
      where("phones.value like ?", "%#{phone.strip}%")
    end

		def by_sms_code(sms_code)
			return all unless sms_code.present?
			where("lower(phone_usages.sms_code) like ?", "%#{sms_code.strip.downcase}%")
		end

    def by_sms_code_presence(sms_code_presence)
      return all unless sms_code_presence.present?
      where("phone_usages.sms_code IS NOT NULL AND phone_usages.sms_code <> ''")
    end

    def by_phone_provider_id(phone_provider_id)
			return all unless phone_provider_id.present?
			where("phone_usages.phone_provider_id = ?", phone_provider_id)
		end

    def by_country_id(country_id)
      return all unless country_id.present?
      where("geobase_countries.id = ?", country_id)
    end

    def by_phone_service_id(phone_service_id)
			return all unless phone_service_id.present?
			where("phone_usages.phone_service_id = ?", phone_service_id)
		end

    def by_phone_service_account_id(phone_service_account_id)
      return all unless phone_service_account_id.present?
      where("phone_usages.phone_service_account_id = ?", phone_service_account_id)
    end

    def by_error_type(error_type)
			return all unless error_type.present?
      if error_type == "0"
        where("phone_usages.error_type IS NULL")
      else
        where("phone_usages.error_type = ?", error_type)
      end
		end

    def by_action_type(action_type)
			return all unless action_type.present?
			where("phone_usages.action_type = ?", action_type)
		end

    def by_web_service_type(web_service_type)
			return all unless web_service_type.present?
			where("phone_usages.web_service_type = ?", web_service_type)
		end

    def by_source_type(source_type)
			return all unless source_type.present?
			where("phone_usages.source_type = ?", source_type)
		end

    def by_phone_usageable_id(phone_usageable_id)
			return all unless phone_usageable_id.present?
			where("phone_usages.phone_usageable_id = ?", phone_usageable_id.strip)
		end

    def by_phone_usageable_type(phone_usageable_type)
			return all unless phone_usageable_type.present?
			where("phone_usages.phone_usageable_type = ?", phone_usageable_type)
		end

    def by_last_days(number_of_days)
      return all unless number_of_days.present?
			where("phone_usages.created_at >= ? AND phone_usages.created_at <= ?", (Time.now - number_of_days.to_i.days).getgm, Time.now.getgm)
    end

    def create_from_params(params, phone_usageable = nil)
      phone_usage = if phone_usageable.present?
        phone_usageable.phone_usages.build
      else
        PhoneUsage.new
      end
      phone_provider = params[:provider].present? ? PhoneProvider.find_by_name(params[:provider]) : nil
      phone_provider = if params[:provider].present?
        if PhoneProvider.find_by_name(params[:provider]).present?
          PhoneProvider.find_by_name(params[:provider])
        else
          PhoneProvider.create(name: params[:provider])
        end
      else
        nil
      end
      phone_service = params[:service].present? ? PhoneService.find_by_name(params[:service]) : nil
      phone_service_account = params[:service_account].present? ? PhoneServiceAccount.includes(:api_account).where("api_accounts.username = ?", params[:service_account]).references(:api_account).first : nil
      phone = if params[:phone].present?
        if Phone.find_by_value(params[:phone]).present?
          Phone.find_by_value(params[:phone])
        else
          country_id = params[:country_code].present? ? Geobase::Country.find_by_code(params[:country_code]).try(:id) : nil
          Phone.create(value: params[:phone], country_id: country_id, status: Phone::STATUSES[:disposable], phone_provider_id: phone_provider.try(:id))
        end
      else
        nil
      end
      phone_provider = phone.phone_provider if phone.present? && phone.phone_provider.present?
      phone_usage.phone_provider = phone_provider
      phone_usage.phone_service = phone_service
      phone_usage.phone_service_account = phone_service_account
      phone_usage.phone = phone
      phone_usage.error_type = params[:error_type].present? ? params[:error_type].try(:to_i) : nil
      phone_usage.action_type = params[:action_type].present? ? params[:action_type].try(:to_i) : nil
      phone_usage.source_type = params[:source_type].present? ? params[:source_type].try(:to_i) : nil
      phone_usage.sms_code = params[:sms_code].present? ? params[:sms_code] : nil
      phone_usage.web_service_type = params[:web_service_type].present? ? params[:web_service_type].try(:to_i) : nil
      phone_usage.amount = params[:amount].present? ? params[:amount].try(:to_f) : nil
      if [%w(SMS-REG SMS-AREA).include?(phone_usage.try(:phone_service_account).try(:phone_service).try(:name)), phone_usage.error_type.nil?, phone_usage.phone_service_account.present?, phone_usage.phone.present?, phone_usage.sms_code.present?].all?
        phone_usage.amount = phone_usage.phone_service_account.current_bid
      end
      phone_usage.call_file_url = params[:call_file_url]
      phone_usage.transaction_id = params[:transaction_id].present? ? params[:transaction_id].to_i : nil
      phone_usage.session_id = params[:session_id]
      phone_usage.save
      phone_usage.update_attributes({created_at: params[:created_at], updated_at: params[:created_at]}) if params[:created_at].present?
      phone_usage
    end
  end
end
