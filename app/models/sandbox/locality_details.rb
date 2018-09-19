class Sandbox::LocalityDetails < ActiveRecord::Base
	include Reversible

	belongs_to :locality, class_name: "Geobase::Locality", foreign_key: "locality_id"
	validates_presence_of :locality_id, message: "Locality cannot be empty"
	validates_uniqueness_of :locality_id, message: "This locality is already in use"

	%w(default_background_image active_background_image).each do |img|
		has_attached_file img, styles: {
			square_32: {geometry: "32x32", processors: [:smart_square_thumbnail]},
			square_64: {geometry: "64x64", processors: [:smart_square_thumbnail]},
			square_256: {geometry: "256x256", processors: [:smart_square_thumbnail]}
		}, preserve_files: true
		validates_attachment_content_type img, allow_blank: true,
			content_type: ["image/jpg", "image/jpeg", "image/png", "image/gif"],
			size: {greater_than: 0.bytes, less_than: 2.megabytes}
	end
end
