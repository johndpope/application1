class Artifacts::DynamicImageText < ActiveRecord::Base
  belongs_to :dynamic_image, class_name: "Artifacts::DynamicImage", foreign_key: "dynamic_image_id"
end
