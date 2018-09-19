class Sandbox::YoutubeChannelImage < ActiveRecord::Base
  extend Enumerize
  belongs_to :sandbox_client, class_name: "::Sandbox::Client", foreign_key: "sandbox_client_id"
  has_one :sandbox_youtube_channel, through: :sandbox_client

  THUMBNAIL_STYLES = {art: '256x144>', icon: '256x256>', video: '256x144>'}
  IMAGE_TYPES = {art: 1, icon: 2, video: 3}
  enumerize :image_type, in: IMAGE_TYPES, scope: true

  has_attached_file :file, :styles => lambda{ |a| a.instance.thumbnail_style }

  validates_attachment_content_type :file,
    content_type: ["image/jpg", "image/jpeg", "image/png", "image/gif", "image/svg+xml"]

  validates :image_type, presence: true

  def thumbnail_style
    return {thumb: (self.image_type.nil? ? '100x100>' : THUMBNAIL_STYLES[self.image_type.to_sym])}
  end

  include Rails.application.routes.url_helpers
  def to_jq_upload
    {
      "id" => read_attribute(:id),
      "name" => read_attribute(:file_file_name),
      "size" => read_attribute(:file_file_size),
      "url" => file.url(:thumb),
      "path" => file.path,
      "sandbox_client_id" => read_attribute(:sandbox_client_id),
      "client" => Sandbox::Client.find(read_attribute(:sandbox_client_id)).client.name,
      "image_type" => read_attribute(:image_type),
      "type" => Sandbox::YoutubeChannelImage::IMAGE_TYPES.key(read_attribute(:image_type)),
      "delete_url" => admin_sandbox_youtube_channel_image_path(self),
      "delete_type" => "DELETE"
    }
  end

end
