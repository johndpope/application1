class Video < ActiveRecord::Base
	belongs_to :video_item, polymorphic: true

	def self.synchronize		
		YoutubeVideo.all.each do |yv|
			video = Video.where("video_item_id = ? AND video_item_type = ?", yv.id, yv.class.name).first
			params = {video_item_id: yv.id, video_item_type: yv.class.name}			
			if(video)
				video.update(params)
			else
				Video.create(params)
			end
			puts "#{yv.class.name} #{yv.id} affected"
		end
		nil
	end
end
