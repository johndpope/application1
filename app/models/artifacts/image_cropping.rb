class Artifacts::ImageCropping < ActiveRecord::Base
	belongs_to :image, class_name: 'Artifacts::Image', foreign_key: 'artifacts_image_id'

	validates :width, presence: true
	validates :height, presence: true
	validates :artifacts_image_id, presence: true

	has_attached_file :file, styles: {original: {processors: [:artifacts_image_cropping]}}
	validates_attachment_content_type :file,
		content_type: ["image/jpg", "image/jpeg", "image/png", "image/gif"]
end
