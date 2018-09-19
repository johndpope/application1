namespace :fujitsu_general_crawling do
  desc "get dealers by company_id from HTML"
  task :parse_dealers => :environment do
    company_ids = []
    state_codes = Geobase::Region.where("level = 1 and country_id = ?", Geobase::Country.find_by_code("US").id).pluck(:code).map{|code| code.split("<sep/>").first.gsub("US-", "").downcase}
    state_codes.each do |state_code, index|
      puts state_code
      r_text = Net::HTTP.get(URI("http://contractors.fujitsugeneral.com/search/states/#{state_code}.htm"))
      response = Nokogiri::HTML(r_text)
      company_ids << response.css("ul.component-link-horiz").css("li.bold").css("a").map{|e| e.attr("href").gsub("/listings/", "").gsub(".htm", "")}
    end
    company_ids.flatten!

    company_ids.each_with_index do |company_id, index|
      puts index + 1
      Delayed::Job.enqueue Crawler::DealersCrawler.new(company_id, 'Fujitsu General'), queue: DelayedJobQueue::DEALERS_CRAWLING
    end
  end
end
