class Templates::DynamicAaeProjectImage < ActiveRecord::Base
	include Reversible

	belongs_to :dynamic_aae_project,
		class_name: "Templates::DynamicAaeProject",
		foreign_key: "dynamic_aae_project_id"
	belongs_to :aae_project_image,
		class_name: "Templates::AaeProjectImage",
		foreign_key: "aae_project_image_id"
	has_one :aae_project, through: :dynamic_aae_project
	has_one :attribution, as: :resource, dependent: :destroy
  has_one :dynamic_aae_project_image, through: :resource, class_name: "Templates::DynamicAaeProjectImage"

	has_attached_file :file, styles: {
		square_32: {geometry: "32x32", processors: [:smart_square_thumbnail]},
		square_64: {geometry: "64x64", processors: [:smart_square_thumbnail]},
		square_256: {geometry: "256x256", processors: [:smart_square_thumbnail]}
	}
	validates_attachment_content_type :file,
		content_type: ["image/jpg", "image/jpeg", "image/png", "image/gif"],
		size: {greater_than: 0.bytes, less_than: 100.megabytes}

	extend Enumerize
	enumerize :image_type, in: Templates::AaeProjectImage::IMAGE_TYPES, scope: true
end
