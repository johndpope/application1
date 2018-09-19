namespace :db do
	namespace :seed do
	  task :import_tripadvisor_landmarks => :environment do
	    puts "import tripadvisor landmarks task started"
			count = 0
			#ActiveRecord::Base.transaction do
				CSV.foreach("db/tripadvisor_landmarks.csv",{:headers=>false, :col_sep=>";", :quote_char=>"\""}) do |row|
					count += 1
					puts count
					category = row[0].strip
					name = row[1].present? ? row[1].strip.gsub("<q>", "\"").gsub("<dc>", ";") : nil
					city_name = row[2].strip
					state_name = row[3].strip
					address = row[4].present? ? row[4].strip.gsub("<q>", "\"").gsub("<dc>", ";") : nil
					phone_number = row[5].present? ? row[5].strip.gsub("<q>", "\"").gsub("<dc>", ";") : nil
					lat_lng = row[6].strip
					latitude = nil
					longitude = nil
					if lat_lng.present? && (lat_lng.include? ",")
						arr = lat_lng.split(",")
						latitude = arr[0].try(:to_f)
						longitude = arr[1].try(:to_f)
					end
					description = row[7].present? ? row[7].strip.gsub("<q>", "\"").gsub("<dc>", ";") : nil
					website = row[8].present? ? row[8].strip.gsub("<q>", "\"").gsub("<dc>", ";") : nil
					url = "http://www.tripadvisor.com/"
					#find city
					locality = Geobase::Locality.joins('LEFT OUTER JOIN geobase_regions ON geobase_localities.primary_region_id = geobase_regions.id')
						.where("geobase_localities.name = ? AND geobase_regions.name = ?", city_name, state_name).first

					if locality.present? && name.present?
						landmark = Geobase::Landmark.where("LOWER(name) = ? AND locality_id = ?", name.downcase, locality.id).first
						if landmark.present?
							landmark.category = category if landmark.category.blank?
							landmark.address = address if landmark.address.blank?
							landmark.phone_number = phone_number if landmark.phone_number.blank?
							landmark.latitude = latitude if landmark.latitude.blank?
							landmark.longitude = longitude if landmark.longitude.blank?
							landmark.website = website if landmark.website.blank?
							landmark.source_url = url if landmark.source_url.blank?
							landmark.save
						else
							landmark = Geobase::Landmark.create(category: category, name: name, locality_id: locality.id,
							address: address, phone_number: phone_number, latitude: latitude, longitude: longitude,
							website: website, source_url: url)
						end
						wordings_size = Wording.where("resource_id = ? AND resource_type = ? AND name = 'short_description'
						AND source IS NOT NULL AND source <> '' AND url = ?", landmark.id, Geobase::Landmark.name, url).size
						if description.present? && landmark.present? && landmark.id.present? && wordings_size == 0
							landmark.wordings << Wording.create(name: 'short_description', source: description, url: url)
						end
					end
				end
			#end
	    puts "import tripadvisor landmarks task finished"
	  end
	end
end
