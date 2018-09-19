namespace :db do
	namespace :seed do
	  task :import_tripadvisor_wordings => :environment do
	    puts "import tripadvisor wordings task started"
			ActiveRecord::Base.transaction do
				CSV.foreach("db/tripadvisor_wordings.csv",{:headers=>false, :col_sep=>";", :quote_char=>"\""}) do |row|
					city_name = row[0].try(:strip)
					state_name = row[1].try(:strip)
					attribute = "short_description"
					value = row[3].try(:strip)
					url = row[2].try(:strip)
					if value.present? && attribute.present? && value.size > 10 && url.present?
						#find city
						locality = Geobase::Locality.joins('LEFT OUTER JOIN geobase_regions ON geobase_localities.primary_region_id = geobase_regions.id')
							.where("geobase_localities.name = ? AND geobase_regions.name = ?", city_name, state_name).first
						if locality.present?
							value = value.gsub("<q>", "\"").gsub("|", ";")
							locality.wordings << Wording.create(name: attribute, source: value, url: url)
						end
					end
				end
			end
	    puts "import tripadvisor wordings task finished"
	  end
	end
end
