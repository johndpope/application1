class Sandbox::Client < ActiveRecord::Base
	include Reversible

	belongs_to :client, class_name: "::Client", foreign_key: "client_id"
	belongs_to :client_category, class_name: "Sandbox::ClientCategory", foreign_key: "client_category_id"
	has_many :video_sets, class_name: "Sandbox::VideoSet", foreign_key: "sandbox_client_id", dependent: :destroy
	has_many :video_campaigns, class_name: "Sandbox::VideoCampaign", foreign_key: "sandbox_client_id", dependent: :destroy
	has_many :campaign_video_stages, through: :video_campaigns

	validates_uniqueness_of :client_id, message: "Broadcaster Client must be unique"
	%w(client_id client_category_id).each do |f|
		validates_presence_of f, message: "#{I18n.t("sandbox.client.#{f}")} cannot be blank"
	end

	%w(logo background_image subject_image).each do |img|
		has_attached_file img, styles: {
			square_32: {geometry: "32x32", processors: [:smart_square_thumbnail]},
			square_64: {geometry: "64x64", processors: [:smart_square_thumbnail]},
			square_256: {geometry: "256x256", processors: [:smart_square_thumbnail]}
		}, preserve_files: true
		validates_attachment_content_type img, allow_blank: true,
			content_type: ["image/jpg", "image/jpeg", "image/png", "image/gif"],
			size: {greater_than: 0.bytes, less_than: 2.megabytes}
	end

	def is_active?
		is_active == true
	end

	before_create do
		self.uuid = SecureRandom.uuid
	end
end
