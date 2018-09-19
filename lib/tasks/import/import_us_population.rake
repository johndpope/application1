namespace :db do
	namespace :seed do
	  task :import_us_population => :environment do
    	puts "1st part of import us population task started"
			count = 0
			country_id = Geobase::Country.where(code: "US").first.id
			CSV.foreach("db/geography/us_population.csv",{:headers=>true, :col_sep=>","}) do |row|
				code = row[0].to_i
				locality_name = row[8]
				state_name = row[9]
				population_2010 = row[12].to_i
				population_2011 = row[13].to_i
				population_2012 = row[14].to_i
				population_2013 = row[15].to_i
				population_2014 = row[16].to_i
				clear_locality_name = locality_name.gsub(" (balance)", "").gsub(" government", "").gsub(" metropolitan", "").gsub(" city", "")
				.gsub(" borough", "").gsub(" township", "").gsub(" town", "").gsub(" (pt.)", "").gsub(" village", "").gsub(" county", "")
				.gsub(" municipality", "").gsub(" Municipality", "").gsub(" metro", "").gsub(" consolidated", "").gsub(" CDP", "")
				.gsub(" UT", "").gsub("Balance of ", "").gsub(" charter", "").gsub(" unified", "").gsub(" urban", "").gsub("City of ", "").strip
				if code != 40
					localities = []
					locality_type = if locality_name.last(4).downcase == "city"
						1
					elsif locality_name.last(4).downcase == "town"
						2
					elsif locality_name.last(7).downcase == "village"
						3
					elsif locality_name.last(7).downcase == "borough"
						6
					elsif locality_name.last(6).downcase == "county"
						0
					else
						nil
					end
					localities = if locality_type.present?
						if locality_type != 0
							Geobase::Locality.joins('LEFT OUTER JOIN geobase_regions ON geobase_localities.primary_region_id = geobase_regions.id')
							.where("LOWER(geobase_localities.name) = ? AND LOWER(geobase_regions.name) = ? AND geobase_regions.country_id = ? AND geobase_localities.locality_type = ? AND geobase_localities.population_2014 IS NULL", clear_locality_name.downcase, state_name.downcase, country_id, locality_type).order("geobase_localities.population desc NULLS LAST").readonly(false)
						else
							clear_locality_name = locality_name.downcase.gsub(" (balance)", "").gsub(" government", "").gsub(" metropolitan", "").gsub(" city", "")
							.gsub(" borough", "").gsub(" township", "").gsub(" town", "").gsub(" (pt.)", "").gsub(" village", "").gsub(" county", "")
							.gsub(" municipality", "").gsub(" metro", "").gsub(" consolidated", "").gsub(" cdp", "").gsub(" ut", "").gsub("balance of ", "")
							.gsub(" charter", "").gsub(" unified", "").gsub(" urban", "").gsub("city of ", "").strip
							Geobase::Region.joins('LEFT OUTER JOIN geobase_regions r1 ON geobase_regions.parent_id = r1.id')
							.where("replace(LOWER(geobase_regions.name), ' city', '') = ? AND LOWER(r1.name) = ? AND geobase_regions.country_id = ? AND geobase_regions.population_2014 IS NULL", clear_locality_name, state_name.downcase, country_id).readonly(false)
						end
					end
					if localities.present? && localities.size == 1
						locality = localities.first
						k = (locality.population.present? && locality.population > 0) ? (population_2014.to_f / locality.population.to_f) : 0
						if locality_type == 0 || (locality.population > 100000 && k >= 0.9 && k <= 1.15) ||
								(locality.population > 50000 && locality.population <= 100000 && k >= 0.9 && k <= 1.2) ||
								(locality.population > 25000 && locality.population <= 50000 && k >= 0.8 && k <= 1.3) ||
								(locality.population > 10000 && locality.population <= 25000 && k >= 0.7 && k <= 1.5) ||
								(locality.population > 5000 && locality.population <= 10000 && k >= 0.6 && k <= 1.75) ||
								(locality.population > 2500 && locality.population <= 5000 && k >= 0.5 && k <= 2) ||
								(locality.population > 1000 && locality.population <= 2500 && k >= 0.4 && k <= 3) ||
								(locality.population > 500 && locality.population <= 1000 && k >= 0.4 && k <= 5) ||
								(locality.population > 250 && locality.population <= 500 && k >= 0.3 && k <= 6) ||
								(locality.population > 100 && locality.population <= 250 && k >= 0.3 && k <= 7) ||
								(locality.population > 75 && locality.population <= 100 && k >= 0.2 && k <= 8) ||
								(locality.population > 50 && locality.population <= 75 && k >= 0.2 && k <= 9) ||
								(locality.population > 0 && locality.population <= 50 && k >= 0.1 && k <= 10) ||
								(locality.population == 0 && population_2014 <= 500)
							locality.population_2010 = population_2010
							locality.population_2011 = population_2011
							locality.population_2012 = population_2012
							locality.population_2013 = population_2013
							locality.population_2014 = population_2014
							#locality.population = population_2014
							locality.save
						end
					end
				else
					state = Geobase::Region.where("LOWER(name) = ? AND population_2014 IS NULL AND level = 1", locality_name.downcase).readonly(false).first
					if state.present?
						state.population_2010 = population_2010
						state.population_2011 = population_2011
						state.population_2012 = population_2012
						state.population_2013 = population_2013
						state.population_2014 = population_2014
						state.population = population_2014
						state.save
					end
				end
				count += 1
				puts count
			end
	    puts "1st part of import us population task finished at: " + Time.now.to_s
			puts "2nd part of import us population task started at: " + Time.now.to_s
			count = 0
			CSV.foreach("db/geography/us_population.csv",{:headers=>true, :col_sep=>","}) do |row|
				code = row[0].to_i
				locality_name = row[8]
				state_name = row[9]
				population_2010 = row[12].to_i
				population_2011 = row[13].to_i
				population_2012 = row[14].to_i
				population_2013 = row[15].to_i
				population_2014 = row[16].to_i
				clear_locality_name = locality_name.gsub(" (balance)", "").gsub(" government", "").gsub(" metropolitan", "").gsub(" city", "")
				.gsub(" borough", "").gsub(" township", "").gsub(" town", "").gsub(" (pt.)", "").gsub(" village", "").gsub(" county", "")
				.gsub(" municipality", "").gsub(" Municipality", "").gsub(" metro", "").gsub(" consolidated", "").gsub(" CDP", "")
				.gsub(" UT", "").gsub("Balance of ", "").gsub(" charter", "").gsub(" unified", "").gsub(" urban", "").gsub("City of ", "").strip
				if code != 40
					localities = []
					locality_type = if locality_name.last(4).downcase == "city"
						1
					elsif locality_name.last(4).downcase == "town"
						2
					elsif locality_name.last(7).downcase == "village"
						3
					elsif locality_name.last(7).downcase == "borough"
						6
					else
						nil
					end
					localities = if locality_type.present?
						localities = Geobase::Locality.joins('LEFT OUTER JOIN geobase_regions ON geobase_localities.primary_region_id = geobase_regions.id')
						.where("LOWER(geobase_localities.name) = ? AND LOWER(geobase_regions.name) = ? AND geobase_regions.country_id = ? AND geobase_localities.locality_type = ? AND geobase_localities.population_2014 IS NULL", clear_locality_name.downcase, state_name.downcase, country_id, locality_type).order("geobase_localities.population desc NULLS LAST").readonly(false)
						if localities.size == 0
							localities = Geobase::Locality.joins('LEFT OUTER JOIN geobase_regions ON geobase_localities.primary_region_id = geobase_regions.id')
							.where("LOWER(geobase_localities.name) = ? AND LOWER(geobase_regions.name) = ? AND geobase_regions.country_id = ? AND geobase_localities.population_2014 IS NULL", clear_locality_name.downcase, state_name.downcase, country_id).order("geobase_localities.population desc NULLS LAST").readonly(false)
						end
						localities
					else
						Geobase::Locality.joins('LEFT OUTER JOIN geobase_regions ON geobase_localities.primary_region_id = geobase_regions.id')
						.where("LOWER(geobase_localities.name) = ? AND LOWER(geobase_regions.name) = ? AND geobase_regions.country_id = ? AND geobase_localities.population_2014 IS NULL", clear_locality_name.downcase, state_name.downcase, country_id).order("geobase_localities.population desc NULLS LAST").readonly(false)
					end
					if localities.size == 0
						clear_locality_name = if locality_name.last(4).downcase == "city"
							clear_locality_name + " City"
						elsif locality_name.last(4).downcase == "town"
							clear_locality_name + " Town"
						elsif locality_name.last(7).downcase == "village"
							clear_locality_name + " Village"
						elsif locality_name.last(7).downcase == "borough"
							clear_locality_name + " Borough"
						else
							clear_locality_name
						end
						localities = Geobase::Locality.joins('LEFT OUTER JOIN geobase_regions ON geobase_localities.primary_region_id = geobase_regions.id')
						.where("LOWER(geobase_localities.name) = ? AND LOWER(geobase_regions.name) = ? AND geobase_regions.country_id = ? AND geobase_localities.population_2014 IS NULL", clear_locality_name.downcase, state_name.downcase, country_id).order("geobase_localities.population desc NULLS LAST").readonly(false)
					end
					clear_locality_name = clear_locality_name.downcase.gsub(" (balance)", "").gsub(" government", "").gsub(" metropolitan", "").gsub(" city", "")
					.gsub(" borough", "").gsub(" township", "").gsub(" town", "").gsub(" (pt.)", "").gsub(" village", "").gsub(" county", "")
					.gsub(" municipality", "").gsub(" metro", "").gsub(" consolidated", "").gsub(" cdp", "").gsub(" ut", "").gsub("balance of ", "")
					.gsub(" charter", "").gsub(" unified", "").gsub(" urban", "").gsub("city of ", "").gsub("-fayette", "").gsub("-davidson", "").gsub("/jefferson", "").strip
					if localities.size == 0
						localities = Geobase::Locality.joins('LEFT OUTER JOIN geobase_regions ON geobase_localities.primary_region_id = geobase_regions.id')
						.where("LOWER(geobase_localities.name) = ? AND LOWER(geobase_regions.name) = ? AND geobase_regions.country_id = ? AND geobase_localities.population_2014 IS NULL", clear_locality_name.downcase, state_name.downcase, country_id).order("geobase_localities.population desc NULLS LAST").readonly(false)
					end
					if localities.size == 0
						localities = Geobase::Locality.joins('LEFT OUTER JOIN geobase_regions ON geobase_localities.primary_region_id = geobase_regions.id
						LEFT OUTER JOIN geobase_regions parent ON geobase_regions.parent_id = parent.id')
						.where("LOWER(geobase_localities.name) = ? AND LOWER(parent.name) = ? AND geobase_regions.country_id = ? AND geobase_localities.population_2014 IS NULL", clear_locality_name.downcase, state_name.downcase, country_id).order("geobase_localities.population desc NULLS LAST").readonly(false)
					end
					if localities.present?
						locality = localities.first
						k = (locality.population.present? && locality.population > 0) ? (population_2014.to_f / locality.population.to_f) : 0
						if (locality.population > 100000 && k >= 0.9 && k <= 1.15) ||
								(locality.population > 50000 && locality.population <= 100000 && k >= 0.9 && k <= 1.2) ||
								(locality.population > 25000 && locality.population <= 50000 && k >= 0.8 && k <= 1.3) ||
								(locality.population > 10000 && locality.population <= 25000 && k >= 0.7 && k <= 1.5) ||
								(locality.population > 5000 && locality.population <= 10000 && k >= 0.6 && k <= 1.75) ||
								(locality.population > 2500 && locality.population <= 5000 && k >= 0.5 && k <= 2) ||
								(locality.population > 1000 && locality.population <= 2500 && k >= 0.4 && k <= 3) ||
								(locality.population > 500 && locality.population <= 1000 && k >= 0.4 && k <= 5) ||
								(locality.population > 250 && locality.population <= 500 && k >= 0.3 && k <= 6) ||
								(locality.population > 100 && locality.population <= 250 && k >= 0.3 && k <= 7) ||
								(locality.population > 75 && locality.population <= 100 && k >= 0.2 && k <= 8) ||
								(locality.population > 50 && locality.population <= 75 && k >= 0.2 && k <= 9) ||
								(locality.population > 0 && locality.population <= 50 && k >= 0.1 && k <= 10) ||
								(locality.population == 0)
							locality.population_2010 = population_2010
							locality.population_2011 = population_2011
							locality.population_2012 = population_2012
							locality.population_2013 = population_2013
							locality.population_2014 = population_2014
							#locality.population = population_2014
							locality.save
						end
					end
				end
				count += 1
				puts count
			end
			puts "2nd part of import us population task finished at: " + Time.now.to_s
	  end
	end
end
