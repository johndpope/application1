namespace :kioti_crawling do
  desc "get dealers by zip-codes"
  task :parse_dealers => :environment do
    codes = Geobase::ZipCode.joins(:primary_region).where("geobase_regions.country_id = ?", Geobase::Country.find_by_code("US").try(:id)).pluck(:code).uniq.sort
    codes.each_with_index do |code,index|
      CrawlerService.kioti_dealers_crawling(code)
    end
  end
end
