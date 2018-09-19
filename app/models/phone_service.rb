class PhoneService < ActiveRecord::Base
  include Reversible
  has_many :phone_service_accounts
  validates :name, presence: true
  before_destroy :delete_link_in_phone_usages_and_phone_phone_service_accounts

  def normalized_website
    @url = self.website
    if @url.blank?
      ''
    else
      @url = "http://#{@url}" unless @url[/\Ahttp:\/\//] || @url[/\Ahttps:\/\//]
      URI.parse(@url).to_s
    end
  end

  private
    def delete_link_in_phone_usages_and_phone_phone_service_accounts
      phone_service_accounts = PhoneServiceAccount.where("phone_service_id = ?", self.id)
      phone_usages = PhoneUsage.where("phone_service_id = ?", self.id)
      phone_service_accounts.update_all(phone_service_id: nil) if phone_service_accounts.present?
      phone_usages.update_all(phone_service_id: nil) if phone_usages.present?
    end
end
