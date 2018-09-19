class BroadcastStream < ActiveRecord::Base
	belongs_to :source_video, foreign_key: :source_video_id

	validates :source_video_id, presence:true, uniqueness: true

	def display_name()
		return source_video.video_file_name
	end

	def self.available_source_videos()								
		return SourceVideo.where.not(id: BroadcastStream.select(:source_video_id).map(&:source_video_id)).order(:video_file_name)
	end
end
