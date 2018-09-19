namespace :claas_crawling do
  desc "get CLAAS dealers from HTML"
  task :parse_dealers => :environment do
    client_id = Client.find_by_name("CLAAS").try(:id)
    paths = ["combine_dealers", "jaguar_dealers", "claas_baler_haytool_dealers", "tractor_dealers"]
    paths.each do |path|
      uri = URI("http://www.claasofamerica.com/sales-financing/dealer-locator/" + path)
      response = Net::HTTP.get(uri)
      html = Nokogiri::HTML(response)
      dealers_rows = html.css("table tr")
      dealers_rows.each do |tr|
        row = tr.children.map(&:text)
        if row.present? && row[5] == "USA"
          dealer = Dealer.where(name: row[0].strip, brand_id: "CLAAS").first_or_initialize
          dealer.address_line1 = row[1].strip
          dealer.city = row[2].strip
          dealer.state = Geobase::Region.where("code like ?  AND level = 1", "US-#{row[3]}%").first.try(:name)
          dealer.zipcode = row[4].strip
          dealer.country = "US"
          dealer.phone1 = row[6].strip
          dealer.target_phone = row[6].strip
          dealer.website = row[7].strip
          dealer.client_id = client_id
          dealer.about = path.humanize
          dealer.save!
        end
      end
    end
  end
end
