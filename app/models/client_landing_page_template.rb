class ClientLandingPageTemplate < ActiveRecord::Base
	has_many :client_landing_pages

	attr_accessor :preview

	has_attached_file :preview,
		path: ':rails_root/public/system/images/client_landing_page_template_previews/:id_partition/:style/:basename.:extension',
		url:  '/system/images/client_landing_page_template_previews/:id_partition/:style/:basename.:extension',
		styles: { thumb: '150x150>' }
	validates_attachment :preview,
		content_type: { content_type: ['image/png', 'image/jpeg', 'image/gif', 'image/bmp'] },
		size: { greater_than: 0.bytes, less_than: 10.megabytes }
	validates :name, :file_name, presence: true
end
