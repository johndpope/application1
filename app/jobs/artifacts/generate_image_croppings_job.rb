module Artifacts
	GenerateImageCroppingsJob = Struct.new(:image_id) do
		ACCEPTABLE_SIZE_INTERPOLATIONS = {
			[720,720] 		=> [500,500],
			[1080, 1080] 	=> [600,600],
			[1280,720] 		=> [650,500],
			[1920, 1080] 	=> [900,600]
		}
    def perform
      image = Artifacts::Image.find(image_id)
      ActiveRecord::Base.transaction do
				if image.file.exists? && !image.width.nil? && !image.height.nil?
					[[720,720],[1080,1080],[1920,1080],[1280,720]].each do |size|
						if image.width >= ACCEPTABLE_SIZE_INTERPOLATIONS[size][0] && image.height >= ACCEPTABLE_SIZE_INTERPOLATIONS[size][1]
							image_cropping = Artifacts::ImageCropping.where(artifacts_image_id: image_id, width: size[0], height: size[1]).first_or_create!
							file = File.open(image.file.path)
							image_cropping.file = file
							file.close
							image_cropping.save!
						end
					end
				end
			end
    end

    def max_attempts
      5
    end

		def max_run_time
			120 #seconds
		end

    def reschedule_at(current_time, attempts)
      current_time + 4.hours
    end
  end
end
