require 'geonames'
namespace :geobase do
  desc "Import geonames data"
  task :import_geonames_data, [:code, :method] => :environment do |t, args|
    @code = args[:code].to_s
    @method = args[:method].to_s
    @error_log ||= Logger.new("#{Rails.root}/log/geonames_#{@code}.log")
    @country = Geobase::Country.find_by_code(@code)
    @username, @proxy_url = nil
    @api_accounts = ApiAccount.where(name: "GEONAMES").shuffle
    puts @code

    def self.import_by_country
      if @country.present?
        @error_log.info("Country #{@code} db import started at: #{Time.now}")
        csv = SmarterCSV.process("public/system/geonames/places/#{@code}.txt",{:quote_char=>"\x00", :headers_in_file=>false, :col_sep=>"\t", user_provided_headers: %i[geonameid name asciiname alternatenames latitude longitude feature_class feature_code country_code cc2 admin1_code admin2_code admin3_code admin4_code population elevation dem timezone modification_date]})
        places_array = csv.select {|e| %w(ADM1 ADM2 ADM3 ADM4 ADM5).include?(e[:feature_code]) || e[:feature_class] == "P" }
        places_array.each_with_index do |row, index|
          begin
            if row[:feature_class] == "P"
              locality = Geobase::Locality.where("geonames_json->>'geonameId' = ?", row[:geonameId].to_s).first_or_initialize
              locality.name = row[:asciiname]
              locality.locality_type = 1 if row[:feature_code] == 'PPL' || row[:feature_code] == 'PPLC'
              locality.geonames_json = {"geonameId"=>row[:geonameid]}
              locality.population = row[:population]
              locality.save
            end
            if row[:feature_class] == "A"
              region = Geobase::Region.where("geonames_json->>'geonameId' = ?", row[:geonameId].to_s).first_or_initialize
              region.name = row[:asciiname]
              region.country_id = @country.id
              #region.level =
              region.geonames_json = {"geonameId"=>row[:geonameid]}
              region.population = row[:population]
              region.save
            end
          rescue Exception => e
            @error_log.info(row.to_s)
            @error_log.info(e.message)
            #@error_log.info(e.backtrace.inspect)
            @error_log.info("Exception at: " + Time.now.to_s)
            @error_log.info("Part #{@code} stopped at index: #{index}")
          end
        end
        @error_log.info("Country #{@code} db import finished at: #{Time.now}")
      end
    end

    def self.import_json
      if @country.present? && @api_accounts.present?
        @error_log.info("Country #{@code} import json started at: #{Time.now}")
        api = GeoNames.new
        api.options[:username] = @username

        localities = Geobase::Locality.where("(geonames_json->>'geonameId')::text IS NOT NULL AND (geonames_json->>'population')::text IS NULL")
        localities.each do |locality|
          geonames_json = api.get({geonameId: locality.geonames_json["geonameId"]}, @proxy_url)
          if geonames_json["status"].present?
            @error_log.error(geonames_json.to_s)
            raise geonames_json["status"]
          end
          locality.geonames_json = geonames_json
          #add latitude and longitude to Geobase::Locality
          previous_region = nil
          (1..5).to_a.reverse.each do |i|
            if geonames_json["adminId#{i}"].present?
              if previous_region.nil?
                #primary_region
                previous_region = Geobase::Region.where("geonames_json->>'geonameId' = ?", geonames_json["adminId#{i}"]).first
                locality.primary_region_id = previous_region.id
                previous_region.level = i
                previous_region.save
              else
                current_region = Geobase::Region.where("geonames_json->>'geonameId' = ?", geonames_json["adminId#{i}"]).first
                previous_region.parent_id = current_region.id
                previous_region.save
                current_region.level = i
                current_region.save
                previous_region = current_region
              end
            end
          end
          locality.save
        end

        regions = Geobase::Region.where("country_id = ? AND (geonames_json->>'geonameId')::text IS NOT NULL AND (geonames_json->>'population')::text IS NULL", @country.id)
        regions.each do |region|
          geonames_json = api.get({geonameId: region.geonames_json["geonameId"]}, @proxy_url)
          if geonames_json["status"].present?
            @error_log.error(geonames_json.to_s)
            raise geonames_json["status"]
          end
          region.geonames_json = geonames_json
          region.save
        end
        @error_log.info("Country #{@code} import json finished at: #{Time.now}")
      end
    end

    def self.rotate_username_and_proxy
      begin
        @api_accounts.rotate!
        api_account = @api_accounts.first
        @username = api_account.username
        email_account = EmailAccount.where("recovery_email like ?", "%#{@username}%").first
        ip_address = email_account.ip_address
        @proxy_url = "http://#{ip_address.address}:#{ip_address.port}"
        @error_log.info("rotate - #{@username} and #{@proxy_url} at: #{Time.now}")
        puts "rotated - #{@username} and #{@proxy_url} at: #{Time.now}"
      rescue Exception => e
        @error_log.info("rotate error - #{@username}")
        @error_log.info(e.message)
        @error_log.info(e.backtrace.inspect)
      end
    end

    import_by_country() if %w(all import).include?(@method)

    begin
      if %w(all json).include?(@method)
        rotate_username_and_proxy()
        import_json()
      end
    rescue Exception => e
      retry
    end
  end
end
