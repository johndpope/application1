namespace :youtube do
	namespace :videos do
		task :create_youtube_video, [:blended_video_id] => :environment do |t, args|
			ActiveRecord::Base.transaction do
				blended_video = BlendedVideo.find(args['blended_video_id'])
				unless Delayed::Job.where("handler like '%CreateYoutubeVideoJob%' and handler like '%blended_video_id: ?\n%'", blended_video.id).exists?
					Delayed::Job.enqueue Youtube::CreateYoutubeVideoJob.new(blended_video.id),
						queue: DelayedJobQueue::YOUTUBE_CREATE_VIDEO
				end
			end
		end

		task :create_youtube_videos_for_accepted_blended_videos => :environment do |t, args|
			BlendedVideo.
				joins(:rendering_settings).
				where('client_rendering_settings.auto_create_youtube_video_content' => true).
				joins("LEFT OUTER JOIN youtube_videos ON youtube_videos.blended_video_id = blended_videos.id").
				where("youtube_videos.id" => nil).
				where('file_file_name IS NOT NULL').
				where('blended_video_accepted(blended_videos.id)::int = 1 AND file_file_name IS NOT NULL').
				find_in_batches(batch_size: 100) do |batch|
					ActiveRecord::Base.transaction do
						batch.each do |bv|
							unless Delayed::Job.where("handler like '%CreateYoutubeVideoJob%' and handler like '%blended_video_id: ?\n%'", bv.id).exists?
								Delayed::Job.enqueue Youtube::CreateYoutubeVideoJob.new(bv.id),
									queue: DelayedJobQueue::YOUTUBE_CREATE_VIDEO
							end
						end
					end
			end
		end
	end
end
