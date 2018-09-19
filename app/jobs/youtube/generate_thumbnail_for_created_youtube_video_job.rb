module Youtube
	BASE_YOUTUBE_VIDEO_THUMBNAIL_DIR = Rails.application.config.temporary_files[:youtube][:videos][:thumbnails]
	GenerateThumbnailForCreatedYoutubeVideoJob = Struct.new(:youtube_video_id) do
		def perform
			ActiveRecord::Base.transaction do
				tmp_youtube_video_thumbnail_file_path = File.join(BASE_YOUTUBE_VIDEO_THUMBNAIL_DIR, "#{SecureRandom.uuid}.png")
				youtube_video = YoutubeVideo.find(youtube_video_id)
				google_account = youtube_video.youtube_channel.google_account
				ea = google_account.email_account
				email_accounts_setup = ea.email_accounts_setup
				youtube_setup = email_accounts_setup.try(:youtube_setup)

				#video thumbnail
				if youtube_setup.use_youtube_video_thumbnail
					unless youtube_video.blended_video.blank?
						begin
							FileUtils.mkdir_p BASE_YOUTUBE_VIDEO_THUMBNAIL_DIR

							bridge_to_sub_texts = Templates::AaeProjectDynamicText.
								with_text_type(:bridge_to_sub_text).
								where(subject_video_id: youtube_video.blended_video.source_video.id).
								pluck(:value)
							video_sub_texts = Templates::AaeProjectDynamicText.
								with_text_type(:video_subject).
								where(subject_video_id: youtube_video.blended_video.source_video.id).
								pluck(:value)
							client_names = youtube_video.client.client_name_tag_list
							location = youtube_video.blended_video.location.formatted_name(primary_region: true, primary_region_code: true)

							Templates::Images::VideoThumbnailGenerator.random_youtube_video_thumbnail(youtube_video.id, {client: client_names,
								bridge_to_sub_text: bridge_to_sub_texts,
								video_subject: video_sub_texts}).write(tmp_youtube_video_thumbnail_file_path){self.quality = 72}

							f = File.open(tmp_youtube_video_thumbnail_file_path, 'r')
							youtube_video.thumbnail = f
							#uncomment when you will add blended video. If ready = true, bot will start activity for uploading video content
							youtube_video.ready = true
              youtube_video.linked = false
							youtube_video.save!
							f.close
						rescue Exception => e
							raise e
						ensure
							FileUtils.rm_rf BASE_YOUTUBE_VIDEO_THUMBNAIL_DIR
						end
					end
				end
			end
		end

		def max_attempts
			self.class.get_max_attempts
		end

		def max_run_time
			300 #seconds
		end

		def reschedule_at(current_time, attempts)
			current_time + 5.minutes
		end

		def self.get_max_attempts
			25
		end
	end
end
