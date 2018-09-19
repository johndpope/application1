class Artifacts::DynamicImageImage < ActiveRecord::Base
	belongs_to :dynamic_image, class_name: "Artifacts::DynamicImage", foreign_key: "artifacts_dynamic_image_id"
	belongs_to :image, class_name: "Artifcats::Image", foreign_key: "artifacts_image_id"
end
