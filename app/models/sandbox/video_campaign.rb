class Sandbox::VideoCampaign < ActiveRecord::Base
	include Reversible

	belongs_to :source_video, class_name: "SourceVideo", foreign_key: "source_video_id"
	belongs_to :sandbox_client, class_name: "Sandbox::Client", foreign_key: "sandbox_client_id"
	has_one :client, through: :sandbox_client
	has_many :campaign_video_stages,
		class_name: "Sandbox::VideoCampaignVideoStage",
		foreign_key: "video_campaign_id",
		dependent: :destroy
	validates_presence_of :sandbox_client_id, message: "Sandbox Client cannot be blank"
	validates_presence_of :title, message: "Title cannot be blank"
end
