module Artifacts
  RetrieveGpsFromImageFilesJob = Struct.new(:image_id) do
    def perform
      image = Artifacts::Image.find(image_id)
      if image.file.exists? && !image.lat.present? && !image.lng.present?
        data = Exif::Data.new(image.file.path)
        if data.present? && data.gps_latitude.present? && data.gps_longitude.present?
          image.lat = data.gps_latitude
          image.lat *= -1 if data.gps_latitude_ref == "S"
          image.lng = data.gps_longitude
          image.lng *= -1 if data.gps_longitude_ref == "W"
          image.save!
        end
      end
    end

    def max_attempts
      24
    end

    def max_run_time
      120 #seconds
    end

    def reschedule_at(current_time, attempts)
      current_time + 4.hours
    end
  end
end
