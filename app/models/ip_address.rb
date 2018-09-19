class IpAddress < ActiveRecord::Base
	include Reversible
	extend Enumerize
	TARGETS = {"proxy" => 1, "free_proxy" => 2}
	enumerize :address_target, :in => TARGETS
	belongs_to :country, class_name: 'Geobase::Country'
	has_many :email_accounts
	validates :address, presence: true
	validates :address, uniqueness: { case_sensitive: false }
	validate :valid_ip_address?
  validates :description, presence: true, if: :additional_use?
	RATING_STATISTICS_PATH = "http://194.31.42.69/out/stats/rating.json"
	NEXT_AVAILABLE_SHUFFLE_LAST_IP_NUMBER = 1
  MINIMUM_OPERATIONAL_RATING = 5
  RATING_GRAB_START_TIME = "05:00:00 UTC"
  LAST_SUCCESS_RATING_GRAB_DATE = "2018-07-06 05:01:00 UTC"

	def valid_ip_address?
    if address.present? && !(IPAddress.valid? address)
      errors.add(:address, "#{address} is not valid ip address")
    end
  end

	class << self
    def rating_successfully_finished?
      if (Setting.get_value_by_name("IpAddress::LAST_SUCCESS_RATING_GRAB_DATE").to_time + 1.day).utc > Time.now.utc
        true
      else
        false
      end
    end

		def update_rating_statistics
			now = Time.now.in_time_zone('Eastern Time (US & Canada)')
			ActiveRecord::Base.logger.info "IP Addresses statistics rating update job : #{now}"
			url = Setting.get_value_by_name("IpAddress::RATING_STATISTICS_PATH")
			result = %x(curl -X GET "#{url}")
			success = false
			begin
				json = JSON.parse(result)
				json.each do |key, value|
					ip_address = IpAddress.where("address = ?", key).first
					if ip_address.present? && value.present?
						stages = value.first
						ip_address.update_attributes(stages.each { |k, v| stages[k] = v.to_s })
						ip_address.rating = ip_address.stage1.to_f + ip_address.stage2.to_f + ip_address.stage3.to_f + ip_address.stage4.to_f + ip_address.stage5.to_f
						ip_address.save
					end
				end
        Utils.pushbullet_broadcast("IP Addresses ratings - SUCCESS", "IP Addresses ratings successfully grabbed at #{Time.now.utc}!") if Rails.env.production?
        setting = Setting.find_by_name("IpAddress::LAST_SUCCESS_RATING_GRAB_DATE")
        setting.value = Time.now.utc.to_s
        setting.save
				success = true
			rescue Exception => e
        Utils.pushbullet_broadcast("IP Addresses ratings - FAILED", "IP Addresses ratings failed to grab at #{Time.now.utc}!") if Rails.env.production?
				ActiveRecord::Base.logger.error e
			end
			success
		end

		def next_available_ip_address(country = nil, address_target = "proxy")
      minimum_operational_rating = Setting.get_value_by_name("IpAddress::MINIMUM_OPERATIONAL_RATING").to_f
      virgin_ip_address, ip_addresses_stat = nil
			if country.present?
        ip_addresses_stat_by_country = EmailAccount.joins("LEFT JOIN ip_addresses ON ip_addresses.id = email_accounts.ip_address_id").by_account_type(EmailAccount.account_type.find_value(:operational).value).where("email_accounts.ip_address_id IS NOT NULL AND ip_addresses.country_id = ?", country.id).group("email_accounts.ip_address_id").order("count(email_accounts.id) ASC").count
        ip_addresses_stat = if ip_addresses_stat_by_country.size > 0
          ip_addresses_stat_by_country
        else
          EmailAccount.by_account_type(EmailAccount.account_type.find_value(:operational).value).where("ip_address_id IS NOT NULL").group("ip_address_id").order("count(id) ASC").count
        end
				virgin_ip_address = if ip_addresses_stat.present?
					IpAddress.where("id not in (?) AND address_target = ? AND country_id = ? AND rating IS NOT NULL AND rating >= ?", ip_addresses_stat.keys, IpAddress.address_target.find_value(address_target).value, country.id, minimum_operational_rating).order("random()").first
				else
					IpAddress.where("address_target = ? AND country_id = ? AND rating IS NOT NULL AND rating >= ? AND last_assigned_at IS NULL", IpAddress.address_target.find_value(address_target).value, country.id, minimum_operational_rating).order("random()").first
				end
      else
        ip_addresses_stat = EmailAccount.by_account_type(EmailAccount.account_type.find_value(:operational).value).where("ip_address_id IS NOT NULL").group("ip_address_id").order("count(id) ASC").count
				virgin_ip_address = if ip_addresses_stat.present?
					IpAddress.where("id not in (?) AND address_target = ? AND rating IS NOT NULL AND rating >= ?", ip_addresses_stat.keys, IpAddress.address_target.find_value(address_target).value, minimum_operational_rating).order("random()").first
				else
					IpAddress.where("address_target = ? AND last_assigned_at IS NULL AND rating IS NOT NULL AND rating >= ?", IpAddress.address_target.find_value(address_target).value, minimum_operational_rating).order("random()").first
				end
      end
			if virgin_ip_address.present?
				virgin_ip_address
			else
				if ip_addresses_stat.present?
          ip_addresses_count = ip_addresses_stat.size >= 3 ? ip_addresses_stat.size : 3
					groups = ip_addresses_stat.to_a.each_slice(ip_addresses_count / 3).to_a.first(3)
					groups_hash = {
						groups[0] => 70,
						groups[1] => 25,
						groups[2] => 5
					}
					pickup = Pickup.new(groups_hash)
					group = pickup.pick
					ids = group.to_h.keys
          if country.present?
  					IpAddress.where("(id in (?) OR last_assigned_at IS NULL) AND address_target = ? AND country_id = ? AND rating IS NOT NULL AND rating >= ?", ids, IpAddress.address_target.find_value(address_target).value, country.id, minimum_operational_rating).order("(CASE WHEN last_assigned_at IS NULL THEN 1 ELSE 0 END) DESC, last_assigned_at ASC").last(Setting.get_value_by_name("IpAddress::NEXT_AVAILABLE_SHUFFLE_LAST_IP_NUMBER").to_i).shuffle.first
          else
  					IpAddress.where("(id in (?) OR last_assigned_at IS NULL) AND address_target = ? AND rating IS NOT NULL AND rating >= ?", ids, IpAddress.address_target.find_value(address_target).value, minimum_operational_rating).order("(CASE WHEN last_assigned_at IS NULL THEN 1 ELSE 0 END) DESC, last_assigned_at ASC").last(Setting.get_value_by_name("IpAddress::NEXT_AVAILABLE_SHUFFLE_LAST_IP_NUMBER").to_i).shuffle.first
          end
				else
					nil
				end
			end
		end

    def return_ip_address(ip_address, by_country = false)
      email_accounts = EmailAccount.by_account_type(EmailAccount.account_type.find_value(:operational).value).where("ip_address_id = ?", ip_address.id)
      email_accounts.each do |ea|
        ea.ip = ea.ip_address.address
        ea.save
      end
      country = ip_address.country
      ip_address.destroy
      email_accounts.each do |ea|
        next_ip_address = if by_country
          IpAddress.next_available_ip_address(country)
        else
          IpAddress.next_available_ip_address
        end
        ea.ip_address = next_ip_address
        ea.save
        next_ip_address.last_assigned_at = Time.now
        next_ip_address.save
      end
    end

		def by_id(id)
			return all unless id.present?
			where("ip_addresses.id = ?", id.strip)
		end

		def by_address(address)
			return all unless address.present?
			where("ip_addresses.address like ?", "%#{address}%")
		end

		def by_port(port)
			return all unless port.present?
			where("ip_addresses.port = ?", port.strip)
		end

		def by_rating(rating)
			return all unless rating.present?
			rating = rating.to_f
			where("ip_addresses.rating >= ? AND ip_addresses.rating < ?", rating - 0.5, rating + 0.5)
		end

		def by_country_id(country_id)
			return all unless country_id.present?
			where("ip_addresses.country_id = ?", country_id)
		end

    def by_additional_use(additional_use)
      return all unless additional_use.present?
      if additional_use == true.to_s
        where("ip_addresses.additional_use = TRUE")
      else
        where("ip_addresses.additional_use IS NOT TRUE")
      end
    end
	end
end
