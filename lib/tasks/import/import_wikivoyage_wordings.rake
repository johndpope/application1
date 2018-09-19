namespace :db do
	namespace :seed do
	  task :import_wikivoyage_wordings => :environment do
	    puts "import wikivoyage wordings task started"
			ActiveRecord::Base.transaction do
				CSV.foreach("db/wikivoyage_wordings.csv",{:headers=>false, :col_sep=>";", :quote_char=>"\""}) do |row|
					city_name = row[3].strip
					state_name = row[4].strip
					attribute = row[5].strip
					value = row[6].strip
					url = row[7].strip
					#find city
					locality = Geobase::Locality.joins('LEFT OUTER JOIN geobase_regions ON geobase_localities.primary_region_id = geobase_regions.id')
						.where("geobase_localities.name = ? AND geobase_regions.name = ?", city_name, state_name).first
					if locality.present? && value.present? && attribute.present? && value.size > 15 && url.present?
						value = value.gsub("<q>", "\"").gsub("|", ";")
						#puts city_name + "---" + state_name + "---" + attribute + "---" + value.first(20) + "---" + url
						locality.wordings << Wording.create(name: attribute, source: value, url: url)
					end
				end
			end
	    puts "import wikivoyage wordings task finished"
	  end
	end
end
