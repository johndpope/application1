module VoipmsService
	PERMINUTE_MONTHLY_PRICE_CAN_LIMIT = 0.85
	PERMINUTE_MONTHLY_PRICE_USA_LIMIT = 0.99
	PERMINUTE_MONTHLY_PRICE_INT_LIMIT = 0.85
	FLAT_SETUP_PRICE_CAN_LIMIT = 1.00
	FLAT_SETUP_PRICE_USA_LIMIT = 1.00
	FLAT_SETUP_PRICE_INT_LIMIT = 1.00
	NEED_SMS = 1
	ROUTING = "account:184251"
	POP = 58
	DIALTIME = 60
	CNAM = 0
	BILLING_TYPE = 1
	PROVINCES = {"Ontario"=>"ON", "Quebec"=>"QC", "Alberta"=>"AB", "British Columbia"=>"BC", "Manitoba"=>"MB", "Nova-scotia"=>"NS", "Newfoundland"=>"NL"}
	STATES = {"Alaska"=>"AK", "Alabama"=>"AL", "Arkansas"=>"AR", "Arizona"=>"AZ", "California"=>"CA", "Colorado"=>"CO", "Connecticut"=>"CT", "District Of Columbia"=>"DC", "Delaware"=>"DE", "Florida"=>"FL", "Georgia"=>"GA", "Hawaii"=>"HI", "Iowa"=>"IA", "Idaho"=>"ID", "Illinois"=>"IL", "Indiana"=>"IN", "Kansas"=>"KS", "Kentucky"=>"KY", "Louisiana"=>"LA", "Massachusetts"=>"MA", "Maryland"=>"MD", "Maine"=>"ME", "Michigan"=>"MI", "Minnesota"=>"MN", "Missouri"=>"MO", "Mississippi"=>"MS", "Montana"=>"MT", "North Carolina"=>"NC", "North Dakota"=>"ND", "Nebraska"=>"NE", "New Hampshire"=>"NH", "New Jersey"=>"NJ", "New Mexico"=>"NM", "Nevada"=>"NV", "New York"=>"NY", "Ohio"=>"OH", "Oklahoma"=>"OK", "Oregon"=>"OR", "Pennsylvania"=>"PA", "Puerto Rico"=>"PR", "Rhode Island"=>"RI", "South Carolina"=>"SC", "South Dakota"=>"SD", "Tennessee"=>"TN", "Texas"=>"TX", "Utah"=>"UT", "Virginia"=>"VA", "Vermont"=>"VT", "Washington"=>"WA", "Wisconsin"=>"WI", "West Virginia"=>"WV", "Wyoming"=>"WY"}
	API_URL = "https://voip.ms/api/v1/rest.php?"
	PROXY_URL = "http://192.95.39.204:8888"
	class << self
		def build_voipms_url(phone_service_account, path, method, params={})
			url = "#{path}api_username=#{phone_service_account.api_account.username}&api_password=#{phone_service_account.api_account.password}&method=#{method}"
			params.each {|key, value| url += "&#{key}=#{value}" }
			URI.escape(url)
		end

		def regional_ratecenters(phone_service_account, path, proxy, method, country_code, region_code)
			params = case country_code
			when "CA"
				{province: region_code}
			when "US"
				{state: region_code}
			end
			regional_ratecenters_url = VoipmsService.build_voipms_url(phone_service_account, path, method, params)
			regional_ratecenters_json = %x(curl -x #{proxy} -X GET "#{regional_ratecenters_url}")
			regional_ratecenters_json = JSON.parse(regional_ratecenters_json)
			ratecenters = regional_ratecenters_json["ratecenters"].present? ? regional_ratecenters_json["ratecenters"].select {|ratecenter| ratecenter["available"] == "yes"}.map{|x| x["ratecenter"]} : []
		end

		def get_regions(phone_service_account, country_code, method, remote = false)
			regions_hash = {}
			proxy = Setting.get_value_by_name('VoipmsService::PROXY_URL')
			path = Setting.get_value_by_name("VoipmsService::API_URL")
			if remote == true
				regions_url = VoipmsService.build_voipms_url(phone_service_account, path, method)
				regions_json = %x(curl -x #{proxy} -X GET "#{regions_url}")
				regions_json = JSON.parse(regions_json)
				if regions_json["status"] == "success"
					regions_hash = case method
					when "getProvinces"
						regions_json["provinces"].map{|x| regions_hash[x["description"].split.map(&:capitalize).join(' ')] = x["province"]}
					when "getStates"
						regions_json["states"].map{|x| regions_hash[x["description"].split.map(&:capitalize).join(' ')] = x["state"]}
					end
				end
			else
				regions_hash = case method
				when "getProvinces"
					provinces = PROVINCES
					provinces.each_value do |province|
						ratecenters = VoipmsService.regional_ratecenters(phone_service_account, path, proxy, "getRateCentersCAN", country_code, province)
						provinces.delete_if {|key, value| value == province } if ratecenters.empty?
					end
					provinces
				when "getStates"
					states = STATES
					# states.each_value do |state|
					# 	ratecenters = VoipmsService.regional_ratecenters(phone_service_account, path, proxy, "getRateCentersUSA", country_code, state)
					# 	states.delete_if {|key, value| value == state } if ratecenters.empty?
					# end
					# states
				end
			end
			regions_hash
		end

		def available_region_dids(phone_service_account, country_code, region_code, amount_limit, perminute_monthly_price_limit, flat_setup_price_limit, need_sms = NEED_SMS, all_ratecenters = false)
			if phone_service_account.present? && phone_service_account.phone_service.name = "VOIP-MS"
				proxy = Setting.get_value_by_name('VoipmsService::PROXY_URL')
				path = Setting.get_value_by_name("VoipmsService::API_URL")
				method = ""
				parameters = {}
				ratecenters = []
				case country_code
				when "CA"
					method = "getDIDsCAN"
					parameters[:province] = region_code
					if !all_ratecenters
						ratecenters = VoipmsService.regional_ratecenters(phone_service_account, path, proxy, "getRateCentersCAN", country_code, region_code).shuffle
						#parameters[:ratecenter] = ratecenters.shuffle.first
					end
				when "US"
					method = "getDIDsUSA"
					parameters[:state] = region_code
					if !all_ratecenters
						ratecenters = VoipmsService.regional_ratecenters(phone_service_account, path, proxy, "getRateCentersUSA", country_code, region_code).shuffle
						#parameters[:ratecenter] = ratecenters.shuffle.first
					end
				end
				#use while loop until find
				all_available_dids = []
				ratecenters.each do |ratecenter|
					parameters[:ratecenter] = ratecenter
					dids_list_url = VoipmsService.build_voipms_url(phone_service_account, path, method, parameters)
					dids_json = %x(curl -x #{proxy} -X GET "#{dids_list_url}")
					dids_json = JSON.parse(dids_json)
					if dids_json["status"] == "success"
						all_available_dids << dids_json["dids"]
					end
					all_available_dids = all_available_dids.flatten
					all_available_dids = all_available_dids.select {|did| did["sms"] == need_sms && did["perminute_monthly"].to_f <= perminute_monthly_price_limit && did["flat_setup"].to_f <= flat_setup_price_limit} if all_available_dids.size > 0
					all_available_dids.shuffle!
					break if all_available_dids.present? && all_available_dids.size >= amount_limit
				end
				all_available_dids.first(amount_limit)
			end
		end

		def orderVoipMsDID(phone_service_account, did_json, country_code, region_code, path, proxy, test = true)
			order_url = VoipmsService.build_voipms_url(phone_service_account, path, "orderDID", {did: did_json['did'], routing: Setting.get_value_by_name("VoipmsService::ROUTING"), failover_busy: Setting.get_value_by_name("VoipmsService::ROUTING"), failover_unreachable: Setting.get_value_by_name("VoipmsService::ROUTING"), failover_noanswer: Setting.get_value_by_name("VoipmsService::ROUTING"), pop: Setting.get_value_by_name("VoipmsService::POP"), dialtime: Setting.get_value_by_name("VoipmsService::DIALTIME"), cnam: Setting.get_value_by_name("VoipmsService::CNAM"), billing_type: Setting.get_value_by_name("VoipmsService::BILLING_TYPE")})
			if test == true
				order_url += "&test=true"
			end
			response = %x(curl -x #{proxy} -X GET "#{order_url}")
			response = JSON.parse(response)
			if response["status"] == "success"
				provider_name = "voip-ms"
				phone_provider = if PhoneProvider.find_by_name(provider_name).present?
					PhoneProvider.find_by_name(provider_name)
				else
					PhoneProvider.create(name: provider_name)
				end
				#find region by region_code and add to phone create if not null and exist
				region_code = "#{country_code}-#{region_code}"
				country_id = Geobase::Country.find_by_code(country_code).try(:id)
				region_id = region_code.present? && country_id.present? ? Geobase::Region.where("code LIKE ? AND country_id = ?", "%#{region_code}%", country_id).first.try(:id) : nil
				enable_sms_url = VoipmsService.build_voipms_url(phone_service_account, path, "setSMS", {did: did_json['did'], enable: 1})
				enable_sms_response = %x(curl -x #{proxy} -X GET "#{enable_sms_url}")
				phone = Phone.create(value: did_json["did"], phone_provider_id: phone_provider.id,
					status: Phone.status.find_value(:permanent).value, phone_type: Phone.phone_type.find_value(:mobile).value,
					country_id: country_id, region_id: region_id, ordered_at: Time.now, expires_at: Time.now + 1.month)
				phone.park_did if phone.id.present?
				phone
			end
		end

		def orderVoipMsDids(phone_service_account, country_code, regions_list, dids_amount)
			report = {success: 0, error: {}}
			if phone_service_account.present? && phone_service_account.phone_service.name = "VOIP-MS" && dids_amount > 0
				proxy = Setting.get_value_by_name('VoipmsService::PROXY_URL')
				path = Setting.get_value_by_name("VoipmsService::API_URL")
				balance = phone_service_account.api_account.api_balance
				perminute_monthly_price_limit = nil
				flat_setup_price_limit = nil
				price_per_did = case country_code
				when "CA"
					perminute_monthly_price_limit = Setting.get_value_by_name("VoipmsService::PERMINUTE_MONTHLY_PRICE_CAN_LIMIT").to_f
					flat_setup_price_limit = Setting.get_value_by_name("VoipmsService::FLAT_SETUP_PRICE_CAN_LIMIT").to_f
				when "US"
					perminute_monthly_price_limit = Setting.get_value_by_name("VoipmsService::PERMINUTE_MONTHLY_PRICE_USA_LIMIT").to_f
					flat_setup_price_limit = Setting.get_value_by_name("VoipmsService::FLAT_SETUP_PRICE_USA_LIMIT").to_f
				else
					perminute_monthly_price_limit = Setting.get_value_by_name("VoipmsService::PERMINUTE_MONTHLY_PRICE_INT_LIMIT").to_f
					flat_setup_price_limit = Setting.get_value_by_name("VoipmsService::FLAT_SETUP_PRICE_INT_LIMIT").to_f
				end
				price_per_did = perminute_monthly_price_limit + flat_setup_price_limit
				if balance >= dids_amount * price_per_did
					if ["CA", "US"].include?(country_code)
						exit_count = 0
						while exit_count < dids_amount do
							regions_list.each do |region_code|
								available_dids = []
								available_dids << VoipmsService.available_region_dids(phone_service_account, country_code, region_code, 1, perminute_monthly_price_limit, flat_setup_price_limit)
								available_dids = available_dids.flatten
								test_env = Rails.env.production? ? false : true
								available_dids.each do |did_json|
									VoipmsService.orderVoipMsDID(phone_service_account, did_json, country_code, region_code, path, proxy, test_env)
								end
								if available_dids.size > 0
									report[:success] += 1
								else
									report[:error][region_code] = report[:error][region_code].to_i + 1
								end
								exit_count += 1
								break if exit_count == dids_amount
							end
						end
					else
					  #international
					end
				end
			end
			report
		end

		def cancel_did(phone_service_account, phone)
			proxy = Setting.get_value_by_name('VoipmsService::PROXY_URL')
			path = Setting.get_value_by_name("VoipmsService::API_URL")
			cancel_did_url = VoipmsService.build_voipms_url(phone_service_account, path, "cancelDID", {did: phone.value})
			if !Rails.env.production?
				cancel_did_url += "&test=true"
			end
			response = %x(curl -x #{proxy} -X GET "#{cancel_did_url}")
			response = JSON.parse(response)
			if response["status"] == "success"
				email_accounts = EmailAccount.all.by_account_type(EmailAccount.account_type.find_value(:operational).value).where("recovery_phone_id = ?", phone.id).readonly(false)
				email_accounts.each{|ea| ea.update({recovery_phone_id: nil, recovery_phone_assigned: nil, recovery_phone_assigned_at: nil, notes: ea.notes.to_s + "\nPrevious recovery did: " + phone.value}) }
				phone.destroy
			end
		end

		def park_did(phone)
			if !phone.parked? && phone.value.present?
				url = Setting.get_value_by_name("Phone::ASTERISK_URL") + Setting.get_value_by_name("Phone::PARK_DID_PATH") + phone.value
				begin
					uri = URI.parse(url)
          request = Net::HTTP::Get.new(uri)
          response = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https', :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |https|
            https.request(request)
          end
					if response.present? && response.is_a?(Net::HTTPSuccess)
						phone.parked = true if (response.body.include? "Successful parked DID!") || (response.body.include? "DID is already parked!")
						phone.park_answer = response.body
						phone.save
					end
				rescue Exception => e
					ActiveRecord::Base.logger.error "Error while parking did: #{e}"
				end
			end
		end

		def next_available_did
			total_recovery_phones_stat = EmailAccount.by_account_type(EmailAccount.account_type.find_value(:operational).value).where("recovery_phone_id IS NOT NULL AND recovery_phone_assigned IS NOT NULL").group("recovery_phone_id").order("count(id) ASC").count
			accounts_per_phone_limit = Setting.get_value_by_name("EmailAccount::GMAIL_ACCOUNTS_PER_PHONE").to_i
      unusable_ids = Phone.where("phone_provider_id = ? AND parked IS TRUE AND usable = FALSE", PhoneProvider.find_by_name('voip-ms').id).pluck(:id)
			available_recovery_phones_stat = total_recovery_phones_stat.reject {|key, value| value >= accounts_per_phone_limit || unusable_ids.include?(key)}
			suspended_did_ids = EmailAccount.by_account_type(EmailAccount.account_type.find_value(:operational).value).where("recovery_phone_id IS NOT NULL AND recovery_phone_assigned IS NULL").pluck(:recovery_phone_id)
			exclude_list = total_recovery_phones_stat.keys + suspended_did_ids
			virgin_did = if exclude_list.present?
				Phone.where("id not in (?) AND phone_provider_id = ? AND parked IS TRUE AND usable IS NOT FALSE", exclude_list, PhoneProvider.find_by_name('voip-ms').id).order("random()").first
			else
				Phone.where("phone_provider_id = ? AND last_assigned_at IS NULL AND parked IS TRUE AND usable IS NOT FALSE", PhoneProvider.find_by_name('voip-ms').id).order("random()").first
			end
			if virgin_did.present?
				virgin_did
			else
				if available_recovery_phones_stat.present?
					for_slice = available_recovery_phones_stat.size / 3
					for_slice = available_recovery_phones_stat.size if for_slice == 0
					groups = available_recovery_phones_stat.to_a.each_slice(for_slice).to_a.first(3)
					groups_hash = {groups[0] => 70, groups[1] => 25, groups[2] => 5}
					groups_hash.delete_if {|key, value| key.nil?}
					pickup = Pickup.new(groups_hash)
					group = pickup.pick
					ids = group.to_h.keys
          h = {}
          ids.each { |id| h[PhoneUsage.select(:created_at).where(phone_id: id).order(created_at: :desc).pluck(:created_at).first] = id }
          h.reject!{ |key, value| key.nil?}
          phone_id = h.sort.first(10).sample.try(:second)
          Phone.find_by_id(phone_id)
          # phone_id = ids.first(10).sample
					# Phone.find_by_id(phone_id)
					# Phone.where("(id in (?) OR last_assigned_at IS NULL) AND phone_provider_id = ? AND parked IS TRUE AND usable IS NOT FALSE", ids, PhoneProvider.find_by_name('voip-ms').id).order("last_assigned_at ASC").first(10).shuffle.first
				else
					nil
				end
			end
		end
	end
end
