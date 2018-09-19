class Sandbox::VideoCampaignVideoStage < ActiveRecord::Base
	include Reversible

	belongs_to :locality, class_name: "Geobase::Locality", foreign_key: "locality_id"
	belongs_to :video_campaign,
		class_name: "Sandbox::VideoCampaign",
		foreign_key: "video_campaign_id"
	has_one :sandbox_client,	through: :video_campaign
	has_one :client, through: :sandbox_client

	has_attached_file :thumbnail, styles: {w60:"60x45", w240: "240x180", w480: "480x360"}, preserve_files: true
	validates_attachment_content_type :thumbnail, allow_blank: true,
		content_type: ["image/jpg", "image/jpeg", "image/png", "image/gif"],
		size: {greater_than: 0.bytes, less_than: 2.megabytes}

	validates_presence_of :title, message: "Title cannot be empty"
	validates_presence_of :video_campaign_id, message: "Video Campaign cannot be empty"
	validates_presence_of :month_nr, message: "Month cannot be empty"
	validates_inclusion_of :month_nr, :in => 1..12, message: "Month should be in range 1..12", allow_blank: true
	validates_presence_of :locality_id, message: "Locality cannot be empty"
end
