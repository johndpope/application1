module Artifacts
  ImageImportJob = Struct.new(:image_type, :image_id) do
    def perform
      image_class = image_type.constantize
      if (image = image_class.unscoped.find(image_id))
        ActiveRecord::Base.transaction { image.import }
      end
    end

    def max_attempts
      1024
    end

		def max_run_time
			300 #seconds
		end

    def reschedule_at(current_time, attempts)
      current_time + 4.hours
    end

    def success(job)
      image_class = image_type.constantize
      if (image = image_class.unscoped.find(image_id))
        ActiveRecord::Base.transaction {
					Delayed::Job.enqueue Artifacts::ImageAspectCroppingJob.new(image_type, image_id),
						queue: DelayedJobQueue::ARTIFACTS_IMAGE_ASCPECT_CROPPING_VARIATIONS,
						priority: DelayedJobPriority::LOW
					Delayed::Job.enqueue Artifacts::GenerateImageCroppingsJob.new(image_id),
						queue: DelayedJobQueue::ARTIFACTS_GENERATE_IMAGE_CROPPINGS,
						priority: DelayedJobPriority::HIGH
          if image.file.exists? && !image.lat.present? && !image.lng.present?
            Delayed::Job.enqueue Artifacts::RetrieveGpsFromImageFilesJob.new(image.id),
              queue: DelayedJobQueue::RETRIEVE_GPS_FROM_IMAGE_FILES,
              priority: DelayedJobPriority::LOW
          end
				}
      end
    end
  end
end
