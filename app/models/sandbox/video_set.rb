class Sandbox::VideoSet < ActiveRecord::Base
	include Reversible

	belongs_to :sandbox_client, class_name: "Sandbox::Client", foreign_key: "sandbox_client_id"
	has_many :videos, class_name: "Sandbox::Video", foreign_key: "sandbox_video_set_id", dependent: :destroy
	has_one :client, through: :sandbox_client

	validates_presence_of :sandbox_client_id, message: "Sandbox Client cannot be blank"

	content_types = {"thumb" => ["image/jpg", "image/jpeg", "image/png", "image/gif"], "blended_sample" => ["video/mp4"]}
	size_limits = {"thumb" => {greater_than: 0.bytes, less_than: 2.megabytes}, "blended_sample" => {greater_than: 0.bytes, less_than: 200.megabytes}}
	styles = {"thumb" => {w60:"60x45", w240: "240x180", w480: "480x360"}, "blended_sample" => {}}
	%w(thumb blended_sample).each do |media_field|
		has_attached_file media_field, styles: styles[media_field], preserve_files: true
		validates_attachment_content_type media_field, allow_blank: true,
			content_type: content_types[media_field], size: size_limits[media_field]
	end

	def get_videos
		types = Templates::VIDEO_CHUNK_TYPES.merge(Templates::GENERAL_TYPES)
		videos.with_video_type *types.keys
	end

	def get_transitions
		videos.with_video_type *Templates::TRANSITION_TYPES.keys
	end
end
