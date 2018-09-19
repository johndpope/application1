class Artifacts::ImagesArtifactsImageCategory < ActiveRecord::Base
  belongs_to :artifacts_images, class_name: 'Artifacts::Image', foreign_key: 'image_id'
  belongs_to :artifacts_image_categories, class_name: 'Artifacts::ImageCategory', foreign_key: 'image_category_id'
end
