class PhoneProvider < ActiveRecord::Base
  include Reversible
  has_many :phones
  validates :name, presence: true
  before_destroy :delete_link_in_phones_and_phone_usages

  private
    def delete_link_in_phones_and_phone_usages
      phones = Phone.where("phone_provider_id = ?", self.id)
      phone_usages = PhoneUsage.where("phone_provider_id = ?", self.id)
      phones.update_all(phone_provider_id: nil) if phones.present?
      phone_usages.update_all(phone_provider_id: nil) if phone_usages.present?
    end
end
