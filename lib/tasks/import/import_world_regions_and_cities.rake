require 'csv'
namespace :db do
	namespace :seed do
	  task :import_world_regions_and_cities, [:task] => :environment do |t, args|
			task = args[:task].try(:to_i)
			class AddTempCodeToGeobaseRegion < ActiveRecord::Migration
				def self.create_temp_column
					add_column :geobase_regions, :temp_code, :string if !column_exists?(:geobase_regions, :temp_code, :string)
				end
			end
			class RemoveTempCodeFromGeobaseRegion < ActiveRecord::Migration
			  def self.destroy_temp_column
			    remove_column :geobase_regions, :temp_code if column_exists?(:geobase_regions, :temp_code, :string)
			  end
			end

			def self.start_part(part_number)
				error_log ||= Logger.new("#{Rails.root}/log/world_cities_part_#{part_number}.log")
				if part_number == 0
					AddTempCodeToGeobaseRegion.create_temp_column
					error_log.info("Part #{part_number} normalize regions started at: " + Time.now.to_s)
					all_regions = Geobase::Region.all
					all_regions.each do |region|
						region.name = I18n.transliterate(region.name)
						region.save
					end
					error_log.info("Part #{part_number} normalize regions finished at: " + Time.now.to_s)

					error_log.info("Part #{part_number} import regions started at: " + Time.now.to_s)
					regions_count = 1
					CSV.foreach("db/geography/world_regions.csv",{:headers=>false, :col_sep=>","}) do |row|
						country_code = row[0].strip.downcase
						temp_code = row[1].strip
						region_name = I18n.transliterate(row[2].strip)
						if ["Queretaro de Arteaga", "Veracruz-Llave", "Yukon Territory"]
							region_name = "Queretaro Arteaga" if region_name == "Queretaro de Arteaga"
							region_name = "Veracruz Llave" if region_name == "Veracruz-Llave"
							region_name = "Yukon" if region_name == "Yukon Territory"
						end
						if country_code != "us"
							if %w(mx ca).include?(country_code)
								region = if country_code == "mx"
									Geobase::Region.joins('LEFT OUTER JOIN geobase_countries ON geobase_countries.id = geobase_regions.country_id')
									.where("LOWER(geobase_regions.name) = ? AND LOWER(geobase_countries.code) = ?", region_name.downcase, country_code).order(:level).readonly(false).first
								else
									Geobase::Region.joins('LEFT OUTER JOIN geobase_countries ON geobase_countries.id = geobase_regions.country_id')
									.where("LOWER(geobase_regions.name) like ? AND LOWER(geobase_countries.code) = ?", "#{region_name.downcase}%", country_code).order(:level).readonly(false).first
								end
								if region.present? && region.temp_code.blank?
									region.temp_code = temp_code
									region.save
									regions_count += 1
								end
							else
								region = Geobase::Region.joins('LEFT OUTER JOIN geobase_countries ON geobase_countries.id = geobase_regions.country_id')
									.where("LOWER(geobase_regions.name) = ? AND LOWER(geobase_countries.code) = ? AND geobase_regions.temp_code = ?", region_name.downcase, country_code, temp_code).order(:level).readonly(false).first
								if region.nil?
									country_id = Geobase::Country.select(:id).where("LOWER(code) = ?", country_code).first.try(:id)
									if country_id.present?
										Geobase::Region.create(name: region_name, temp_code: temp_code, country_id: country_id, level: 1)
										regions_count += 1
									end
								elsif region.temp_code.blank?
									region.temp_code = temp_code
									region.save
								end
							end
						end
					end
					error_log.info("Part #{part_number} finished at: " + Time.now.to_s)
				else
					cities_count = 1

					error_log.info("Part #{part_number} started at: " + Time.now.to_s)
					CSV.foreach("db/geography/world_cities_part_#{part_number}.csv",{:headers=>false, :col_sep=>",", :encoding=>"ISO-8859-1"}) do |row|
						begin
							country_code = row[0].downcase
							city_name = I18n.transliterate(row[2])
							temp_code = row[3]
							population = row[4].try(:to_i)
							latitude = row[5].try(:to_f)
							longitude = row[6].try(:to_f)
							if country_code != "us"
								region_id = Geobase::Region.joins('LEFT OUTER JOIN geobase_countries ON geobase_countries.id = geobase_regions.country_id')
									.where("geobase_regions.temp_code = ? AND LOWER(geobase_countries.code) = ?", temp_code, country_code).first.try(:id)
								if region_id.present?
									if %w(mx ca).include?(country_code)
										city = Geobase::Locality.where("LOWER(name) = ? AND primary_region_id = ?", city_name, region_id).first
										if city.present? && population.present?
											city.population = population
											city.save
										end
									else
										if Geobase::Locality.where("name = ? AND primary_region_id = ? AND created_at IS NOT NULL", city_name, region_id).size == 0
											city = Geobase::Locality.create(name: city_name, population: population, primary_region_id: region_id, locality_type: 1)
											city.zip_codes << Geobase::ZipCode.create(latitude: latitude, longitude: longitude, primary_region_id: region_id) if latitude.present? && longitude.present?
										end
									end
								end
							end
							cities_count += 1
						rescue Exception => e
							error_log.info(row.to_s)
							error_log.info(e.message)
							error_log.info(e.backtrace.inspect)
							error_log.info("Exception at: " + Time.now.to_s)
							error_log.info("Part #{part_number} stopped at line: #{cities_count}")
						end
					end
					error_log.info("Part #{part_number} finished at: " + Time.now.to_s)
				end
			end

			if [0,1,2,3,4,5,6,7,8,9,10].include?(task)
				start_part(task)
			end
			if task == 11
				error_log ||= Logger.new("#{Rails.root}/log/world_cities_#{task}.log")
				error_log.info("Part #{task} finished at: " + Time.now.to_s)
				RemoveTempCodeFromGeobaseRegion.destroy_temp_column
				error_log.info("Part #{task} finished at: " + Time.now.to_s)
			end
	  end
	end
end
