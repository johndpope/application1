module Artifacts
	ReprocessImageThumbnailJob = Struct.new(:image_id) do
		def perform
      image = Artifacts::Image.find(image_id)
			if image.file.exists?
				image.file.reprocess!(:thumb)
			end
    end

    def max_attempts
      1024
    end

		def max_run_time
			120 #seconds
		end

    def reschedule_at(current_time, attempts)
      current_time + 4.hours
    end
	end
end
