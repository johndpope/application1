class Artifacts::Author < ActiveRecord::Base
  include Reversible
  has_attached_file :avatar, preserve_files: true
  validates_attachment_content_type :avatar,
    content_type: ["image/jpg", "image/jpeg", "image/png", "image/gif"]

	def formatted_name
		parts = []
		unless name.blank?
			parts << name
			parts << "/"
		end
		parts << username unless username.blank?
		parts.join(' ')
	end
end
