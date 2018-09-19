class Artifacts::ImageCategory < ActiveRecord::Base
  has_and_belongs_to_many :artifacts_images, class_name: 'Artifacts::Image', :join_table => "artifacts_images_artifacts_image_categories"

  belongs_to :parent, class_name: 'Artifacts::ImageCategory', foreign_key: :parent_id
  has_many :children, class_name: 'Artifacts::ImageCategory', foreign_key: :parent_id
end
