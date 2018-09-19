module Crawler
  DealersCrawler = Struct.new(:code, :brand_id) do
    def perform
      case brand_id
      when 'Kioti'
        CrawlerService.kioti_dealers_crawling(code)
      when 'John Deere'
        CrawlerService.deere_dealers_crawling(code)
      when 'RUUD'
        CrawlerService.ruud_dealers_crawling(code)
      when 'Fujitsu General'
        #code is company_id
        CrawlerService.fujitsu_general_dealers_crawling(code)
      when 'Yanmar'
        CrawlerService.yanmar_dealers_first_crawling(code)
      else
        true
      end
    end

    def max_attempts
      1024
    end

    def max_run_time
      300 #seconds
    end

    def reschedule_at(current_time, attempts)
      current_time + 6.hour
    end

    def success(job)

    end
  end
end
