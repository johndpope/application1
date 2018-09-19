class ClientDonor < ActiveRecord::Base
	belongs_to :client
	belongs_to :donor, class_name: 'Client', foreign_key: 'donor_id'

	before_destroy :destroy_related_donor_videos

	private
		def destroy_related_donor_videos
			donor_video_ids = donor.source_videos.pluck(:id)
			ClientDonorSourceVideo.where(source_video_id: donor_video_ids).delete_all
		end
end
