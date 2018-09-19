module SandboxMigration
	class CampaignVideo < ActiveRecord::Base
		use_connection_ninja(:sandbox)
		
		belongs_to :locality, foreign_key: 'locality_id', class_name: 'Geobase::Locality'
		belongs_to :campaign_video_set
		has_one :client, through: :campaign_video_set

		validates :views, inclusion: {in: 1001..99999, message: "should be in range [1001..99999]"}

		has_attached_file :thumbnail,
			path: ":rails_root/public/system/images/campaign_video_thumbnails/:partition_id/:style/:basename.:extension",
			url: "/system/images/campaign_video_thumbnails/:partition_id/:style/:basename.:extension",
			styles: {thumb: "100>x100>"}

		validates_attachment :thumbnail, allow_blank: true,
			content_type: {content_type: ['image/png', 'image/jpeg', 'image/gif'], message: 'Invalid content type'},
			size: {greater_than: 0.bytes, less_than: 10.megabytes, message: 'File size exceeds the limit allowed'}

		def self.by_video_set_and_locality(video_set_id, locality_id)
			where(campaign_video_set_id: video_set_id, locality_id: locality_id).order(:month_nr)
		end
	end
end
