module SandboxMigration
	class Client < ActiveRecord::Base
		use_connection_ninja(:sandbox)
		
		has_many :client_images, class_name: 'Image'
		has_many :video_sets, order: 'order_nr, id'
		has_many :images
		has_many :campaign_video_sets
		has_many :campaign_videos, through: :campaign_video_sets
		has_many :contact_us
		belongs_to :category

		attr_accessor :delete_logo
		before_save { logo.clear if delete_logo == '1' }

		has_attached_file :logo,
			path: ':rails_root/public/system/clients/logos/:id/:style/:basename.:extension',
			url: '/system/clients/logos/:id/:style/:basename.:extension',
			styles: { thumb: '100x100>' }

		validates_attachment :logo, allow_blank: true,
			content_type: { content_type: ['image/png', 'image/jpeg', 'image/gif'], message: 'Invalid content type' },
			size: { greater_than: 0.bytes, less_than: 1.megabytes, message: 'File size exceeds the limit allowed' }

		[:background_image, :subject_image].each do | image_entity |
			has_attached_file image_entity,
				path: ":rails_root/public/system/clients/#{image_entity.to_s.pluralize(2)}/:id/:style/:basename.:extension",
				url: "/system/clients/#{image_entity.to_s.pluralize(2)}/:id/:style/:basename.:extension",
				styles: { thumb: '100>x100>' }

			validates_attachment image_entity, allow_blank: true,
				content_type: { content_type: ['image/png', 'image/jpeg', 'image/gif'], message: 'Invalid content type' },
				size: { greater_than: 0.bytes, less_than: 10.megabytes, message: 'File size exceeds the limit allowed' }
		end

		validates_presence_of :name

		before_save :set_slug
		before_create { self.uuid = SecureRandom::uuid }

		def output_image_samples(set_type)
			Image::output_image_samples(self, set_type)
		end

		private
			def set_slug
				self.slug = self.name.to_url
			end
	end
end
