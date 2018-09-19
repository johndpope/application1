class Phone < ActiveRecord::Base
  include Reversible
  extend Enumerize
  STATUSES = {:permanent => 1, :disposable => 2}
  PHONE_TYPES = {:business => 1, :mobile => 2, :home => 3, :fax => 4}
	ASTERISK_URL = "http://voip.valynteen.net:90"
	PARK_DID_PATH = "/gapi/parkDID.php?did="
  enumerize :status, :in => STATUSES
  enumerize :phone_type, :in => PHONE_TYPES
  belongs_to :phone_provider, foreign_key: :phone_provider_id
  belongs_to :locality, foreign_key: :locality_id, class_name: 'Geobase::Locality'
  belongs_to :region, foreign_key: :region_id, class_name: 'Geobase::Region'
  belongs_to :country, foreign_key: :country_id, class_name: 'Geobase::Country'
  has_many :email_accounts, foreign_key: :recovery_phone_id
  has_many :facebook_accounts
  has_many :phone_calls
  validates :value, presence: true
  before_destroy :delete_link_in_phone_usages

	def email_accounts_assigned_size(status = nil)
    case status
    when "active"
      EmailAccount.by_is_active("true").by_account_type(EmailAccount.account_type.find_value(:operational).value).where("recovery_phone_assigned = true AND recovery_phone_id = ?", self.id).size
    when "inactive"
      EmailAccount.by_is_active("false").by_deleted("false").by_account_type(EmailAccount.account_type.find_value(:operational).value).where("recovery_phone_assigned = true AND recovery_phone_id = ?", self.id).size
    when "deleted"
      EmailAccount.by_deleted("true").by_account_type(EmailAccount.account_type.find_value(:operational).value).where("recovery_phone_assigned = true AND recovery_phone_id = ?", self.id).size
    else
      EmailAccount.by_account_type(EmailAccount.account_type.find_value(:operational).value).where("recovery_phone_assigned = true AND recovery_phone_id = ?", self.id).size
    end
	end



	def youtube_channels_assigned_size
		PhoneUsage.where("phone_id = ? AND action_type = ? and error_type IS NULL", self.id, PhoneUsage.action_type.find_value("youtube business channel verification").value).size
	end

  def facebook_accounts_assigned_size
    FacebookAccount.where("phone_id = ?", self.id).size
  end

	def park_did
		if self.phone_provider.try(:name) == 'voip-ms' && !self.parked
			VoipmsService.park_did(self)
		end
	end

	class << self
		def by_id(id)
			return all unless id.present?
			where("phones.id = ?", id.strip)
		end

		def by_value(value)
			return all unless value.present?
      values = value.split(",")
      if values.size > 1
        where("phones.value in (?)", values.map(&:strip))
      else
        where("phones.value like ?", "%#{value.strip}%")
      end
		end

		def by_status(status)
			return all unless status.present?
			where("phones.status = ?", status)
		end

		def by_phone_provider_id(phone_provider_id)
			return all unless phone_provider_id.present?
			where("phones.phone_provider_id = ?", phone_provider_id)
		end

		def by_country_id(country_id)
			return all unless country_id.present?
			where("phones.country_id = ?", country_id)
		end

		def by_region_id(region_id)
			return all unless region_id.present?
			where("phones.region_id = ?", region_id)
		end

    def by_usable(usable)
      return all unless usable.present?
      if usable == true.to_s
        where("phones.usable IS NOT FALSE")
      else
        where("phones.usable = FALSE")
      end
    end

    def by_facebook_usable(facebook_usable)
      return all unless facebook_usable.present?
      if facebook_usable == true.to_s
        where("phones.facebook_usable IS NOT FALSE")
      else
        where("phones.facebook_usable = FALSE")
      end
    end
	end

  private
    def delete_link_in_phone_usages
      phone_usages = PhoneUsage.where("phone_id = ?", self.id)
      phone_calls = PhoneCall.where("phone_id = ?", self.id)
      phone_usages.update_all(phone_id: nil) if phone_usages.present?
      phone_calls.update_all(phone_id: nil) if phone_calls.present?
    end
end
