module CrawlerService
  class << self
    def exmark_dealer_parse(full_path)
      default_country_id = Geobase::Country.find_by_code("US").id
      client = Client.find_by_name("Exmark")
      dealer_uri = URI(full_path)
      dealer_r_text = Net::HTTP.get(dealer_uri)
      if !dealer_r_text.include?("An error occurred while processing your request")
        dealer_response = Nokogiri::HTML(dealer_r_text)
        title = dealer_response.css(".body-content").first.css(".row h1").first.text.sub("About ", "").split(" - ")
        brand_id = "Exmark"
        dealer_name = title.first
        locality_name = title.second.to_s.split(", ").first
        region_abbr = title.second.to_s.split(", ").second
        description = dealer_response.css(".body-content").first.css("#AboutUs").try(:first).try(:text).to_s.strip
        contact_info = description.include?("Contact us at") ? description.split(". ").last.to_s.sub("Contact us at ", "").split(" or ") : []
        phone = contact_info.first
        email = contact_info.last.present? ? contact_info.last.chomp(".") : nil
        service_areas = dealer_response.css(".body-content")[1].try(:css, "p").try(:first).try(:text).to_s.strip
        zip_list = service_areas.gsub(/[a-zA-Z() ]/, "").split(",").to_a
        zipcode_list = zip_list.to_s
        zip_count = zip_list.size
        address_info = dealer_response.css(".site-map").first.css(".col-sm-5").first
        website = address_info.css("a").first.try(:attr, "href")
        address = address_info.css("p").first.try(:text).to_s.split("Visit Our Website").first.strip.chomp(";").strip.split("\r\n")
        address_line1 = address[0]
        address_line2 = address[1]
        zipcode = address.last.sub(title.second.to_s, "").strip
        state = ""
        cities = []
        country = if zipcode.first(5).to_i.to_s.size == 5
          zipcode = zipcode.first(5)
          state = Geobase::Region.where("code like ? AND level = 1", "US-#{region_abbr}%").first.try(:name)
          if zip_list.present?
            geo_zips = Geobase::ZipCode.where("code IN (?)", zip_list.map(&:to_s)).map {|e| e.localities.map(&:id)}.flatten
            if geo_zips.present?
              cities = Geobase::Locality.joins("LEFT JOIN geobase_regions ON geobase_regions.id = geobase_localities.primary_region_id").where("geobase_localities.id in (?) AND geobase_regions.country_id = ?", geo_zips, default_country_id).map(&:id).map(&:to_s)
            end
          end
          cities.flatten!
          cities.uniq!
          "US"
        else
          state = Geobase::Region.where("code = ? AND level = 1 AND country_id = ?", region_abbr, Geobase::Country.find_by_code("CA").id).first.try(:name) || region_abbr
          "CA"
        end
        if Dealer.where(brand_id: "Exmark", target_phone: phone, zipcode: zipcode, name: dealer_name).size == 0
          ActiveRecord::Base.transaction do
            dealer = Dealer.create(name: dealer_name, brand_id: brand_id, target_phone: phone, website: website, email: email, address_line1: address_line1, address_line2: address_line2, zipcode: zipcode, city: locality_name, state: state, zipcode_list: zipcode_list, zip_count: zip_count, country: country, cities: cities, client_id: client.try(:id), dealer_gui: full_path, industry_id: 994)
            if description.present?
              dealer.wordings << Wording.new(name: 'long_description', source: description)
            end
          end
        end
      else
        raise "An error occurred while processing your request"
      end
    end

    def exmark_dealers_crawling
      uri = URI("https://www.exmark.com/home/dealerlist")
      r_text = Net::HTTP.get(uri)
      response = Nokogiri::HTML(r_text)
      urls = response.css(".body-content").first.css("a").map{|e| e.attr("href")}
      urls.each do |url|
        CrawlerService.delay(queue: DelayedJobQueue::OTHER).exmark_dealer_parse("https://www.exmark.com" + url)
      end
    end

    def yanmar_dealers_first_crawling(code)
      default_country_id = Geobase::Country.find_by_code("US").id
      client_id = Client.find_by_name("Yanmar").try(:id)
      text = %x(curl 'https://www.yanmartractor.com/locator/locate?Length=7' -H 'Origin: https://www.yanmartractor.com' -H 'X-Requested-With: XMLHttpRequest' --data 'Query=#{code}&Radius=50&X-Requested-With=XMLHttpRequest')
      response = Nokogiri::HTML(text)
      if response.css("ul").present? && response.css("ul").css(".result-item").present?
        response.css("ul").css(".result-item").each do |li|
          lat = li.attr("data-lat")
          lng = li.attr("data-lat")
          dealer_name = li.attr("data-name")
          address = li.css(".address").try(:first).try(:text).to_s.strip.chomp(";").strip.split("\r\n").map(&:strip)
          address_line1 = address[0].to_s
          address_line2 = address[1].to_s
          city = address_line2.split(",").first
          region_abbr = address_line2.split(",")[1].to_s.strip.split(" ")[0]
          zip = address_line2.split(",")[1].to_s.sub(region_abbr.to_s, "").strip
          zipcode = [5, 9].include?(zip.gsub(/\D/, "").size) ? zip.first(5) : zip
          cities = []
          state = region_abbr.present? ? Geobase::Region.where("code like ? AND level = 1", "US-#{region_abbr}%").first.try(:name) : nil
          if zipcode.present?
            geo_zip = Geobase::ZipCode.find_by_code(zipcode)
            if geo_zip.present? && geo_zip.localities.map(&:id).present?
              cities = Geobase::Locality.joins("LEFT JOIN geobase_regions ON geobase_regions.id = geobase_localities.primary_region_id").where("geobase_localities.id in (?) AND geobase_regions.country_id = ?", geo_zip.localities.map(&:id), [5, 9].include?(zip.gsub(/\D/, "").size) ? default_country_id : Geobase::Country.find_by_code("CA").try(:id)).map(&:id).map(&:to_s)
            end
          end
          cities.flatten!
          cities.uniq!
          phone = li.css(".phone").try(:first).try(:text).to_s.gsub("Phone: ", "")
          fax = li.css(".fax").try(:first).try(:text)
          url = li.css("h3") && li.css("h3").css("a").present? ? li.css("h3").css("a").attr("href").value : nil
          ActiveRecord::Base.transaction do
            dealer = Dealer.where(brand_id: "Yanmar", target_phone: phone, zipcode: zipcode, name: dealer_name, dealer_gui: url, client_id: client_id, industry_id: 994).first_or_initialize
            dealer_persisted = dealer.id.present?
            attributes = {brand_id: "Yanmar", name: dealer_name, latitude: lat, longitude: lng, dealer_gui: url, target_phone: phone, fax: fax, address_line1: address_line1, address_line2: address_line2, zipcode: zipcode, city: city, state: state, country: "US", cities: cities, client_id: client_id, industry_id: 994}
            dealer.attributes = attributes
            dealer.save
            if !dealer_persisted && dealer.id.present? && dealer.dealer_gui.present?
              CrawlerService.delay(queue: DelayedJobQueue::OTHER).yanmar_dealers_second_crawling(dealer.id)
            end
          end
        end
      end
    end

    def yanmar_dealers_second_crawling(dealer_id)
      dealer = Dealer.find(dealer_id)
      uri = URI(dealer.dealer_gui)
      r_text = Net::HTTP.get(uri)
      response = Nokogiri::HTML(r_text)
      if !dealer.zipcode.present? && response.css(".address").present?
        zip = response.css(".address").first.text.strip.split(",").last.strip.split(" ").last.strip
        zipcode = [5, 9].include?(zip.gsub(/\D/, "").size) ? zip.first(5) : zip
        dealer.zipcode = zipcode
        cities = []
        if zipcode.present?
          geo_zip = Geobase::ZipCode.find_by_code(zipcode)
          if geo_zip.present? && geo_zip.localities.map(&:id).present?
            default_country_id = Geobase::Country.find_by_code("US").id
            cities = Geobase::Locality.joins("LEFT JOIN geobase_regions ON geobase_regions.id = geobase_localities.primary_region_id").where("geobase_localities.id in (?) AND geobase_regions.country_id = ?", geo_zip.localities.map(&:id), [5, 9].include?(zip.gsub(/\D/, "").size) ? default_country_id : Geobase::Country.find_by_code("CA").try(:id)).map(&:id).map(&:to_s)
          end
        end
        cities.flatten!
        cities.uniq!
        dealer.cities = cities
      end
      email = response.css("#li_email").present? && response.css("#li_email").css("a").present? ? response.css("#li_email").css("a").attr("href").value.sub("mailto:", "") : nil
      website = response.css("#li_website").present? && response.css("#li_website").css("a").present? ? response.css("#li_website").css("a").attr("href").value : nil
      working_hours = response.css(".hours").present? ? response.css(".hours").first.children.map(&:text).map(&:strip).reject(&:blank?).join("\n") : nil
      dealer.email = email
      dealer.website = website
      dealer.about = working_hours
      dealer.save
      if response.css("#dealerDescription").present?
        dealer.wordings << Wording.new(name: 'long_description', source: response.css("#dealerDescription").children.map(&:text).map(&:strip).reject(&:blank?).join("\n"))
      end
    end

    def kioti_dealers_crawling(code)
      client_id = Client.find_by_name("Kioti Tractor").try(:id)
      uri = URI("http://www.kioti.com/wp-content/themes/2016-main/kiotimap/_includes/genXML.php?zip=#{code}")
      r_text = Net::HTTP.get(uri)
      raise "Invalid query" if r_text.include?("Invalid query")
      response = Nokogiri::XML(r_text)
      dealers = response.children.try(:children).to_a
      dealers.each do |item|
        mapaddress = item.attr("mapaddress").to_s.strip
        state = Geobase::Region.where("code like ? AND level = 1", "US-#{mapaddress.split(',')[-2].strip}%").first.try(:name)
        if state.present?
          ActiveRecord::Base.transaction do
            dealer = Dealer.where(company_id: item.attr("dealerID").to_s.strip.to_i).first_or_initialize
            dealer.client_id = client_id
            dealer.name = item.attr("name").strip
            dealer.brand_id = "Kioti"
            dealer.email = item.attr("email").strip
            dealer.phone1 = item.attr("main_phone").strip
            dealer.fax = item.attr("fax").strip
            dealer.address_line1 = mapaddress.split(",").first.to_s.strip
            dealer.address_line2 = (mapaddress.split(",") - [dealer.address_line1]).join(",").strip
            dealer.city = mapaddress.split(",")[-3].strip
            dealer.state = state
            dealer.country = "US"
            dealer.latitude = item.attr("lat").to_f
            dealer.longitude = item.attr("lng").to_f
            zipcode = mapaddress.split(",")[-1].split("-").first.strip
            zipcode = case zipcode.size
            when 5
              zipcode
            when 4
              "0" + zipcode
            when 3
              "00" + zipcode
            when 2
              "000" + zipcode
            when 1
              "0000" + zipcode
            when 0
              nil
            else
              nil
            end
            dealer.zipcode = zipcode
            dealer.website = item.attr("website").strip
            dealer.target_phone = item.attr("main_phone").strip
            dealer.save
          end
        end
      end
    end

    def deere_dealers_crawling(code)
      zip_code = Geobase::ZipCode.includes(:primary_region).where("geobase_zip_codes.code = ? AND geobase_regions.country_id = ?", code, Geobase::Country.find_by_code("US").id).references(:primary_region).first
      client_id = Client.find_by_name("John Deere").try(:id)
      categories = [2, 3, 4, 5, 6, 7, 60, 97]
      categories.each do |category|
        r_text = Net::HTTP.get(URI("https://dealerlocator.deere.com/servlet/ajax/getLocations?lat=#{zip_code.latitude}&long=#{zip_code.longitude}&locale=en_US&country=US&uom=MI&filterElement=#{category}&_=1504768361943"))
        response = JSON.load(r_text)
        if response.present?
          dealers = response["locations"].to_a
          dealers.each do |item|
            ActiveRecord::Base.transaction do
              address = item["formattedAddress"].to_a
              dealer = Dealer.where(company_id: item["locationId"], name: item["locationName"].strip).first_or_initialize
              dealer.client_id = client_id
              dealer.brand_id = "John Deere"
              dealer.address_line1 = address.first
              dealer.address_line2 = address.second
              if address.second.present?
                dealer.zipcode = address.second.split(" ").last.to_s.first(5)
                dealer.state = Geobase::Region.where("code like ? AND level = 1", "US-#{address.second.split(' ')[-2].strip}%").first.try(:name)
                dealer.city = address.second.gsub(" #{address.second.split(' ')[-2].strip} #{address.second.split(' ')[-1].strip}", "").strip.titleize
              end
              dealer.country = "US"
              dealer.latitude = item["latitude"].to_f
              dealer.longitude = item["longitude"].to_f
              contactDetail = item["contactDetail"]
              if contactDetail.present?
                dealer.email = contactDetail["email"].strip if contactDetail["email"]
                if contactDetail["phone"]
                  dealer.phone1 = contactDetail["phone"].strip
                  dealer.target_phone = contactDetail["phone"].strip
                end
                dealer.fax = contactDetail["fax"].strip if contactDetail["fax"]
                dealer.website = contactDetail["website"].strip if contactDetail["website"]
              end
              dealer.save
            end
          end
        end
      end
    end

    def fujitsu_general_dealers_crawling(company_id)
      ActiveRecord::Base.transaction do
        r_text = Net::HTTP.get(URI("http://contractors.fujitsugeneral.com/listings/#{company_id}_contact.htm"))
        response = Nokogiri::HTML(r_text)
        dealer = Dealer.where(company_id: company_id, name: response.css("#contents .row")[1].css(".component-h-lv3").text.strip).first_or_initialize
        address = response.css("#contents .row")[1].css(".col-1-2")[0].css("p")[1].text
        if address.present?
          dealer.address_line1 = address.split("\r\n\t\t").first
          dealer.address_line2 = address.split("\r\n\t\t").second
          dealer.city = dealer.address_line2.split(",").first.strip.titleize
          second_part = dealer.address_line2.split(",").second.strip.split(" ")
          if second_part.present?
            dealer.zipcode = second_part.last.strip
            dealer.state = Geobase::Region.where("code like ? AND level = 1", "US-#{second_part.first.strip}%").first.try(:name)
          end
        end
        dealer.country = "US"
        phones = response.css("#contents .row")[1].css(".col-1-2")[1].css(".component-normal-dl-10em")[0].css("dd")[0].text.strip.delete!("^\u{0000}-\u{007F}")
        if phones.present? && !phones.include?("miles")
          phones = phones.gsub("&nbsp;", "").split("cell#").map(&:strip)
          dealer.phone1 = phones.first.strip
          dealer.phone2 = phones.second.strip if phones.second.present?
          dealer.phone3 = phones.third.strip if phones.third.present?
          dealer.target_phone = dealer.phone1
        end
        website = response.css("#contents .row")[1].css(".col-1-2")[1].css("p.arrow")[0]
        dealer.website = website.text.strip if website.present?
        dealer.brand_id = "Fujitsu General"
        dealer.dealer_type = "Contractor"
        dealer.save
      end
    end

    def ruud_dealers_crawling(code)
      client_id = Client.find_by_name("RUUD").try(:id)
      r_text = Net::HTTP.get(URI("https://www.ruud.com/media/code/getData.php?service=getDealersJSONString&HeatingAndCooling=1&TanklessWaterHeaters=1&ResidentialWaterHeaters=1&CommercialWaterHeaters=1&SolarWaterHeaters=1&PoolAndSpaWaterHeaters=1&HomeGenerators=1&bKwikComfort=1&bPPlus=1&bProPartner=1&bASP=1&PostalCode=#{code}&Distance=25&bDesignStar=false&bTC=false&brand=bRuud"))
      response = JSON.load(r_text)
      dealers = response["Contractors"]
      dealers.each do |item|
        ActiveRecord::Base.transaction do
          dealer = Dealer.where(company_id: item["OrganizationID"], name: item["OrganizationName"].strip).first_or_initialize
          dealer.client_id = client_id
          dealer.brand_id = "RUUD"
          dealer.address_line1 = item["AddressLine1"].to_s.strip
          dealer.zipcode = item["postalcode"].to_s.strip.first(5)
          dealer.state = Geobase::Region.where("code like ? AND level = 1", "US-#{item['State'].to_s.strip}%").first.try(:name)
          dealer.city = item['City'].to_s.strip.titleize
          dealer.country = "US"
          dealer.latitude = item["Latitude"].to_f if item["Latitude"].present?
          dealer.longitude = item["Longitude"].to_f if item["Longitude"].present?
          dealer.phone1 = item["Phone"].strip
          dealer.phone2 = item["TrackingPhone"].strip
          dealer.target_phone = item["Phone"].strip
          dealer.dealer_type = item["OrganizationType"]
          dealer.website = item["WebSite"].to_s.strip
          dealer.about = item["AboutUs"].to_s.strip
          dealer.save
        end
      end
    end

    def add_info(locality, json_full_path)
      error_messages = []
      response = Net::HTTP.get_response(URI.parse(json_full_path))

      if response.body.present?
        json = JSON.load(response.body)
        if json["description"].present? && json["description_type"].present?
          wording = Wording.where(name: json["description_type"].try(:strip), source: json["description"].try(:strip), resource: locality).first_or_initialize
          wording.url = json["source_url"].try(:strip)
          wording_source = Wording.where(name: 'source', source: json["description"].try(:strip), resource: locality).first_or_initialize
          wording_source.url = json["source_url"].try(:strip)
          error_messages << "Locality description was not saved" unless wording.save
          error_messages << "Locality source description was not saved" unless wording_source.save
        else
          error_messages << "Locality description is empty"
        end

        if json["comments"].present?
          json["comments"].each do |comment_json|
            if comment_json["description"].present? && comment_json["description_type"].present?
              wording_comment = Wording.where(name: comment_json["description_type"].try(:strip), source: comment_json["description"].try(:strip), resource: locality).first_or_initialize
              wording_comment.url = comment_json["source_url"].try(:strip)
              error_messages << "Locality comment ##{comment_json[:id]} was not saved" unless wording_comment.save
            end
          end
        end

        if json["landmarks"].present?
          json["landmarks"].each do |landmark_json|
            landmark_description = landmark_json["description"].try(:strip)
            landmark_description_type = landmark_json["description_type"].try(:strip)
            landmark_params = {
              name: landmark_json["name"].try(:strip),
              locality_id: locality.id,
              latitude: landmark_json["latitude"],
              longitude: landmark_json["longitude"],
              category: landmark_json["category"].try(:strip),
              subcategory: landmark_json["subcategory"].try(:strip),
              address: landmark_json["address"].try(:strip),
              phone_number: landmark_json["phone_number"].try(:strip),
              website: landmark_json["website"].try(:strip),
              source_url: landmark_json["source_url"].try(:strip)
            }
            landmark_params.delete_if {|k,v| v.blank?}
            landmark = nil
            landmark_saved = if landmark_params[:name] && landmark_params[:category].present?
              landmark = Geobase::Landmark.where("LOWER(name) = ? AND locality_id = ? AND category = ? AND (subcategory IS NULL OR subcategory = ?) AND latitude = ? AND longitude = ?", landmark_params[:name].downcase, locality.id, landmark_params[:category], landmark_params[:subcategory], landmark_params[:latitude], landmark_params[:longitude]).first
              landmark = Geobase::Landmark.where("LOWER(name) = ? AND locality_id = ? AND category = ? AND (subcategory IS NULL OR subcategory = ?) AND latitude IS NULL AND longitude IS NULL", landmark_params[:name].downcase, locality.id, landmark_params[:category], landmark_params[:subcategory]).first if !landmark.present? && landmark_params[:latitude].present? && landmark_params[:longitude].present?
              if landmark.present?
                landmark_params.delete(:subcategory) if landmark.subcategory.present?
                landmark.update_attributes(landmark_params) ? true : false
              else
                landmark = Geobase::Landmark.create(landmark_params)
                landmark.id.present? ? true : false
              end
            else
              false
            end
            if landmark_saved && landmark.present?
              if landmark_description.present? && landmark_description_type.present?
                landmark_wording = Wording.where(name: landmark_description_type, source: landmark_description, resource: landmark).first_or_initialize
                landmark_wording.url = landmark_params[:source_url]
                landmark_wording_source = Wording.where(name: 'source', source: landmark_description, resource: landmark).first_or_initialize
                landmark_wording_source.url = landmark_params[:source_url]
                error_messages << "Landmark ##{landmark_json['id']} description was not saved!" unless landmark_wording.save
                error_messages << "Landmark ##{landmark_json['id']} source description was not saved!" unless landmark_wording_source.save
              end
              if landmark_json["comments"].present?
                landmark_json["comments"].each do |landmark_comment_json|
                  if landmark_comment_json["description"].present? && landmark_comment_json["description_type"].present?
                    landmark_wording_comment = Wording.where(name: landmark_comment_json["description_type"].try(:strip), source: landmark_comment_json["description"].try(:strip), resource: landmark).first_or_initialize
                    landmark_wording_comment.url = landmark_comment_json["source_url"].try(:strip)
                    error_messages << "Landmark comment ##{landmark_comment_json['id']} was not saved" unless landmark_wording_comment.save
                  end
                end
              end
            end
          end
        end

        if json["neighbourhoods"].present?
          json["neighbourhoods"].each do |neighbourhood_json|
            neighbourhood_description = neighbourhood_json["description"].try(:strip)
            neighbourhood_description_type = neighbourhood_json["description_type"].try(:strip)
            neighbourhood_params = {
              name: neighbourhood_json["name"].try(:strip),
              locality_id: locality.id,
              latitude: neighbourhood_json["latitude"],
              longitude: neighbourhood_json["longitude"],
              category: neighbourhood_json["category"].try(:strip),
              subcategory: neighbourhood_json["subcategory"].try(:strip),
              address: neighbourhood_json["address"].try(:strip),
              phone_number: neighbourhood_json["phone_number"].try(:strip),
              website: neighbourhood_json["website"].try(:strip),
              source_url: neighbourhood_json["source_url"].try(:strip)
            }
            neighbourhood_params.delete_if {|k,v| v.blank?}
            neighbourhood = nil
            neighbourhood_saved = if neighbourhood_params[:name] && neighbourhood_params[:locality_id].present?
              neighbourhood = Geobase::Neighbourhood.where("LOWER(name) = ? AND locality_id = ?", neighbourhood_params[:name].downcase, locality.id).first
              if neighbourhood.present?
                neighbourhood.update_attributes(neighbourhood_params) ? true : false
              else
                neighbourhood = Geobase::Neighbourhood.create(neighbourhood_params)
                neighbourhood.id.present? ? true : false
              end
            else
              false
            end
            if neighbourhood_saved && neighbourhood.present?
              if neighbourhood_description.present? && neighbourhood_description_type.present?
                neighbourhood_wording = Wording.where(name: neighbourhood_description_type, source: neighbourhood_description, resource: neighbourhood).first_or_initialize
                neighbourhood_wording.url = neighbourhood_params[:source_url]
                neighbourhood_wording_source = Wording.where(name: 'source', source: neighbourhood_description, resource: neighbourhood).first_or_initialize
                neighbourhood_wording_source.url = neighbourhood_params[:source_url]
                neighbourhood_wording_source.save
                error_messages << "Neighbourhood ##{neighbourhood_json[:id]} description was not saved" unless neighbourhood_wording.save
                error_messages << "Neighbourhood ##{neighbourhood_json[:id]} source description was not saved" unless neighbourhood_wording_source.save
              end
              if neighbourhood_json["comments"].present?
                neighbourhood_json["comments"].each do |neighbourhood_comment_json|
                  if neighbourhood_comment_json["description"].present? && neighbourhood_comment_json["description_type"].present?
                    neighbourhood_wording_comment = Wording.where(name: neighbourhood_comment_json["description_type"], source: neighbourhood_comment_json["description"], resource: neighbourhood).first_or_initialize
                    neighbourhood_wording_comment.url = neighbourhood_comment_json["source_url"]
                    error_messages << "Neighbourhood comment ##{neighbourhood_comment_json['id']} was not saved" unless neighbourhood_wording_comment.save
                  end
                end
              end
              if neighbourhood_json["landmarks"].present?
                neighbourhood_json["landmarks"].each do |neighbourhood_landmark_json|
                  neighbourhood_landmark_params = {
                    name: neighbourhood_landmark_json["name"].try(:strip),
                    latitude: neighbourhood_landmark_json["latitude"],
                    longitude: neighbourhood_landmark_json["longitude"],
                    category: neighbourhood_landmark_json["category"].try(:strip)
                  }
                  neighbourhood_landmark = Geobase::Landmark.where("LOWER(name) = ? AND locality_id = ? AND category = ? AND latitude = ? AND longitude = ? AND neighbourhood_id IS NULL", neighbourhood_landmark_params[:name].downcase, locality.id, neighbourhood_landmark_params[:category], neighbourhood_landmark_params[:latitude], neighbourhood_landmark_params[:longitude]).first
                  if neighbourhood_landmark.present?
                    neighbourhood_landmark.neighbourhood_id = neighbourhood.id
                    neighbourhood_landmark.save
                  end
                end
              end
            end
          end
        end
      else
        error_messages << "JSON file is empty"
      end

      job = Job.where(queue: 'geobase_localities_init', resource_id: locality.id).order(created_at: :desc).first
      if job.present?
        job.status = Job.status.find_value("Parsing finished").value
        job.save
      end

      if error_messages.present?
        #render json: {status: 500, messages: error_messages.join(" | ")}, status: 500
        logger ||= Logger.new("#{Rails.root}/log/crawler.log", 10, 100.megabytes)
        logger.info("\n--------------------------------------------------------\nError messages for locality #{locality.id} at #{Time.now.utc}:\n#{error_messages.join(' | ')}")
        false
      else
        true
      end
    end
  end
end
