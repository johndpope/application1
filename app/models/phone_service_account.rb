class PhoneServiceAccount < ActiveRecord::Base
  include Reversible

  belongs_to :phone_service, foreign_key: :phone_service_id
  has_one :api_account, as: :resource, dependent: :destroy
  validates_presence_of :phone_service
  accepts_nested_attributes_for :api_account

  before_destroy :delete_link_in_phone_usages
  SMS_AREA_MINIMUM_AVAILABLE_PHONES = 25

	def username
		self.api_account.try(:username)
	end

  def self.sms_area_available_numbers
    response = {status: 200}
    tries = 5
    begin
      phone_service_account = PhoneServiceAccount.joins(:phone_service).where("phone_services.name = 'SMS-AREA'").first
      api_account = ApiAccount.where(name: "SMS-AREA").last
      method = "getActivationSummary"
      sms_area_api_url = "http://sms-area.org/api/handler.php?method=#{method}&key="
      url = sms_area_api_url + api_account.api_key
      uri = URI.parse(url)
      get_response = Net::HTTP.get_response(uri)
      if get_response.is_a?(Net::HTTPSuccess)
        activation_summary_string = get_response.body
        if activation_summary_string.include? "success"
          activation_summary_json = JSON.parse(activation_summary_string)
          number_of_available_phones = activation_summary_json["data"]["summary"].present? ? activation_summary_json["data"]["summary"].values.map{|e| e["gm"]}.compact.map{|e| e.select{|k,v| k.to_f < phone_service_account.current_bid}}.map{|e| e.values}.flatten.inject(&:+).to_i : 0
          response[:number_of_available_phones] = number_of_available_phones
          response[:allowed] = number_of_available_phones >= Setting.get_value_by_name("PhoneServiceAccount::SMS_AREA_MINIMUM_AVAILABLE_PHONES").to_i
        else
          raise 'An error has occured.'
        end
      else
        raise 'An error has occured.'
      end
    rescue
      puts tries
      unless (tries -= 1).zero?
        sleep 5
        retry
      else
        response = {status: 500}
      end
    end
    response
  end

  private
    def delete_link_in_phone_usages
      phone_usages = PhoneUsage.where("phone_service_account_id = ?", self.id)
      phone_usages.update_all(phone_service_account_id: nil) if phone_usages.present?
    end
end
