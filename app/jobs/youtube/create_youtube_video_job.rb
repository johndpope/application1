module Youtube
	CreateYoutubeVideoJob = Struct.new(:blended_video_id) do
		def perform
			ActiveRecord::Base.transaction do
				unless YoutubeVideo.exists?(blended_video_id: blended_video_id)
					blended_video = BlendedVideo.find(blended_video_id)
					unless blended_video.file.blank?
						youtube_video = blended_video.youtube_channel.generate_video(blended_video.id)
					end
				end
			end
		end

		def max_attempts
			self.class.get_max_attempts
		end

		def max_run_time
			600 #seconds
		end

		def reschedule_at(current_time, attempts)
			current_time + 5.minutes
		end

		def success(job)
			ActiveRecord::Base.transaction do
				blended_video = BlendedVideo.find(blended_video_id)
				youtube_video = blended_video.youtube_video
				google_account = youtube_video.youtube_channel.google_account
				ea = google_account.email_account
				email_accounts_setup = ea.email_accounts_setup
				youtube_setup = email_accounts_setup.try(:youtube_setup)

				if youtube_setup.use_youtube_video_thumbnail
					Delayed::Job.enqueue Youtube::GenerateThumbnailForCreatedYoutubeVideoJob.new(youtube_video.id),
						queue: DelayedJobQueue::YOUTUBE_CREATE_VIDEO_THUMBNAIL_FOR_GENERATED_VIDEO,
						priority: DelayedJobPriority::MEDIUM
				else
					#uncomment when you will add blended video. If ready = true, bot will start activity for uploading video content
					youtube_video.ready = true
					youtube_video.save!
				end
			end
		end

		def self.get_max_attempts
			10
		end
	end
end
