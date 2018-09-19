namespace :dealers_crawling do
    desc "get dealers by zip-codes"
    task :parse_dealers, [:brand] => [:environment] do |t, args|

      codes = Geobase::ZipCode.joins(:primary_region).where("geobase_regions.country_id = 1").pluck(:code).uniq.sort

      client_id = case args[:brand]
      when "AS"
        Client.find_by_name("American Standard").try(:id)
      when "Trane"
        Client.find_by_name("Trane").try(:id)
      else
        nil
      end

      t1 = Time.now
      codes.each_with_index do |code,index|
        uri = URI("https://1mnl7m6a2e.execute-api.us-east-1.amazonaws.com/grd/dealers/locations?brand=#{args[:brand]}&distance=&zipcode=#{code}")

        response = JSON.parse(Net::HTTP.get(uri))
        dealers = response['dealers']
        puts "#{index}|#{code}|#{dealers.blank? ? '-' : '+'}"

        unless dealers.blank?
          dealers.each do |item|
            data = item['data']
            fuseInfo = item['fuseInfo']
            unless data.blank?
              dealer = Dealer.where(company_id: data['companyID'], dealer_gui: data['dealerGUI']).first_or_initialize
              dealer.active = data["active"]
              dealer.client_id = client_id
              dealer.show_dealer = data["showDealer"]
              dealer.dealer_gui = data["dealerGUI"]
              dealer.distributor_gui = data["distributorGUI"]
              dealer.company_id = data["companyID"]
              dealer.dealer_type = data["dealerType"]
              dealer.brand_id = data["brandID"] == 'AS' ? "American Standard" : data["brandID"]
              dealer.tcs_id = data["tcsID"]
              dealer.district = data["district"]
              dealer.contract = data["contract"]
              dealer.charter_member_date = data["charterMemberDate"]
              dealer.name = data["name"]
              dealer.logo_url = data["logoURL"]
              dealer.email = data["email"]
              dealer.phone1 = data["phone1"]
              dealer.phone2 = data["phone2"]
              dealer.phone3 = data["phone3"]
              dealer.address_line1 = data["addressLine1"]
              dealer.address_line2 = data["addressLine2"]
              dealer.city = data["city"]
              dealer.state = data["state"]
              dealer.country = data["country"]
              dealer.latitude = data["latitude"]
              dealer.longitude = data["longitude"]
              dealer.zipcode = data["zipcode"]
              dealer.zipcode_list = data["zipcodeList"].to_s
              dealer.zip_count = data["zipCount"]
              dealer.service_areas = data["serviceAreas"]
              dealer.week_hours = data["weekHours"]
              dealer.website = data["website"]
              dealer.finance_url = data["financeURL"]
              dealer.show_financing = data["showFinancing"]
              dealer.score = data["score"]
              dealer.total_response_count = data["totalResponseCount"]
              dealer.nate_certified = data["nateCertified"]
              dealer.nexia_dealer = data["nexiaDealer"]
              dealer.display_support = data["displaySupport"]

              dealer.emergency_service = data["emergencyService"]
              dealer.tos_accepted = data["tosAccepted"]
              dealer.envirowise = data["envirowise"]
              dealer.spanish = data["spanish"]
              dealer.ductless = data["ductless"]
              dealer.tune_up_preventative_maintenance = data["tuneUpPreventativeMaintenance"]
              dealer.last_mod_date = data["lastModDate"]
              dealer.google_reviews = data["googleReviews"]
              if fuseInfo.present?
                dealer.target_phone = fuseInfo["targetPhone"]
                dealer.permalease_phone = fuseInfo["permaleasePhone"]
                dealer.routing_group = fuseInfo["routingGroup"]
              end
              dealer.save!
            end
          end
        end

      end

    t2 = Time.now
    puts "TIME: #{t2 - t1} sec. | #{((t2 - t1) / 60).round(1)} min"
    end
end
