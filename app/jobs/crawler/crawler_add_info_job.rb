module Crawler
  CrawlerAddInfoJob = Struct.new(:locality_id, :json_full_path) do
    def perform
      begin
        locality = Geobase::Locality.find(locality_id)
        ActiveRecord::Base.transaction do
          CrawlerService.add_info(locality, json_full_path)
        end
      rescue Exception => e
        begin
          job = Job.where(queue: 'geobase_localities_init', resource_id: locality_id).order(created_at: :desc).first
          if job.present?
            job.status = Job.status.find_value("Parsing failed").value
            job.save
          end
        rescue
        end
        raise e
      end
    end

    def max_attempts
      1
    end

    def max_run_time
      900 #seconds
    end

    def reschedule_at(current_time, attempts)
      current_time + 1.hour
    end

    def success(job)

    end
  end
end
