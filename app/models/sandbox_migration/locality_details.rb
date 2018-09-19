module SandboxMigration
	class LocalityDetails < ActiveRecord::Base
		use_connection_ninja(:sandbox)
		
		belongs_to :locality, foreign_key: 'locality_id', class_name: 'Geobase::Locality'

		[:default_background_image, :active_background_image].each do |image_entity|
			has_attached_file image_entity,
				path: ":rails_root/public/system/images/locality_details/#{image_entity.to_s.pluralize(2)}/:id/:style/:basename.:extension",
				url: "/system/images/locality_details/#{image_entity.to_s.pluralize(2)}/:id/:style/:basename.:extension",
				styles: {thumb: "100>x100>"}

			validates_attachment image_entity, allow_blank: true,
				content_type: {content_type: ['image/png', 'image/jpeg', 'image/gif'], message: 'Invalid content type'},
				size: {greater_than: 0.bytes, less_than: 10.megabytes, message: 'File size exceeds the limit allowed'}
		end

		def self.by_locality(locality_id)
			LocalityDetails.where(locality_id: locality_id).first
		end
	end
end
