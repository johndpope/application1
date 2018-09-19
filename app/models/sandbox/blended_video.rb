class Sandbox::BlendedVideo < ActiveRecord::Base
	has_attached_file :file

	validates_attachment :file, allow_blank: true,
		content_type: {content_type: ['video/mp4'], message: 'Invalid content type'},
		size: {greater_than: 0.bytes, less_than: 800.megabytes, message: 'File size exceeds the limit allowed'}
end
