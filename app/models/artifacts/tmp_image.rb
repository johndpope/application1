class Artifacts::TmpImage < ActiveRecord::Base
  has_attached_file :file
  validates_attachment_content_type :file, :content_type=>['image/jpeg', 'image/png', 'image/gif', 'image/jpg']
end
