module Artifacts
  ImageAspectCroppingJob = Struct.new(:image_type, :image_id) do
    def perform
      image_class = image_type.constantize
      if (image = image_class.unscoped.find(image_id))
        ActiveRecord::Base.transaction { image.make_aspect_cropping_variations }
      end
    end

    def max_attempts
      1024
    end

		def max_run_time
			1800 #seconds
		end

    def reschedule_at(current_time, attempts)
      current_time + 4.hours
    end
  end
end
