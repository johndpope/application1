module SandboxMigration
	class CampaignVideoSet < ActiveRecord::Base
		use_connection_ninja(:sandbox)
		
		has_many :campaign_videos
		belongs_to :client
	end
end
