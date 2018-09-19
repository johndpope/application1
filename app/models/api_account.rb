class ApiAccount < ActiveRecord::Base
  include Reversible
  belongs_to :resource, polymorphic: true
  validates :website, :username, :password, presence: true
  validates_uniqueness_of :username, :scope => :website
  after_destroy :delete_phone_service_account
  extend Enumerize
  enumerize :currency, :in=> ConstantsService.currencies

  def api_balance
    balance_value = nil
    begin
      if website == 'https://anti-captcha.com'
        method = "getbalance"
        uri =URI.parse( "http://anti-captcha.com/res.php?key=#{api_key}&action=#{method}")
        response = Net::HTTP.get_response(uri)
        if response.is_a?(Net::HTTPSuccess)
          balance_value = response.body
        end
      end
      if website == 'http://sms-reg.com'
        method = "getBalance"
        sMS_REG_API_URL = "http://api.sms-reg.com/#{method}.php?apikey="
        url = sMS_REG_API_URL + api_key
        balance_string = %x(curl -X GET "#{url}")
        if balance_string.include? "balance"
          balance_json = JSON.parse(balance_string)
          balance_value = balance_json["balance"]
        end
      end
      if website == 'http://sms-area.org'
        method = "getBalance"
        sMS_AREA_API_URL = "http://sms-area.org/api/handler.php?method=#{method}&key="
        url = sMS_AREA_API_URL + api_key
        balance_string = %x(curl -X GET "#{url}")
        if balance_string.include? "balance"
          balance_json = JSON.parse(balance_string)
          balance_value = balance_json["data"]["balance"]
        end
      end
      if website == 'http://voip.ms'
        path = Setting.get_value_by_name("VoipmsService::API_URL")
        method = "getBalance"
        url = VoipmsService.build_voipms_url(self.resource, path, method, {email: self.registration_email})
        balance_string = %x(curl -x #{Setting.get_value_by_name('VoipmsService::PROXY_URL')} -X GET "#{url}")
        if balance_string.include? "balance"
          balance_json = JSON.parse(balance_string)
          balance_value = balance_json["balance"]["current_balance"]
        end
      end
      if balance_value.present?
        self.balance = balance_value.to_f.round(2)
        self.save
      end
      self.balance
    rescue Exception => e
      ActiveRecord::Base.logger.error "Error in getting balance through the API: #{e}"
    end
  end

  class << self
    def by_id(id)
      return all unless id.present?
      where('api_accounts.id = ?', id.strip)
    end

    def by_names(name)
      return all unless name.present?
      where('lower(api_accounts.name) like ?', "%#{name.downcase}%")
    end

    def by_website(website)
      return all unless website.present?
      where('lower(api_accounts.website) like ?', "%#{website.downcase}%")
    end

    def by_username(username)
      return all unless username.present?
      where('api_accounts.username = ?', username.strip)
    end

    def names_list
      ApiAccount.select(:name).distinct.where('name IS NOT NULL').order(:name).pluck(:name)
    end

    def update_api_balance
      if Rails.env.production?
        api_accounts = ApiAccount.all
        api_accounts.each {|aa| aa.try(:api_balance)}
      end
    end
  end

  private

    def delete_phone_service_account
      PhoneServiceAccount.where("id = ?", self.resource_id).first.try(:destroy) if self.resource_type == 'PhoneServiceAccount'
    end
end
