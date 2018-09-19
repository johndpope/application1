class Screenshot < ActiveRecord::Base
  belongs_to :screenshotable, polymorphic: true
  attr_accessor :image
  has_attached_file :image,
    path: ":rails_root/public/system/images/screenshots/:id_partition/:style/:basename.:extension",
    url:  "/system/images/screenshots/:id_partition/:style/:basename.:extension",
    styles: {thumb:"150x150>"}
  validates_attachment :image,
    content_type: {content_type: ['image/png','image/jpeg', 'image/gif', 'image/bmp']},
    size: {greater_than: 0.bytes, less_than: 10.megabytes}
end
