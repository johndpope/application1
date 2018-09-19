module BlendedVideos
	BlendVideoSetJob = Struct.new(:blended_video_id) do
		def perform
			ActiveRecord::Base.transaction do
				blended_video = BlendedVideo.find(blended_video_id)
				if blended_video.accepted? && blended_video.file.blank?
					output = nil
					begin
						video_files = blended_video.blended_video_chunks.order(order_nr: :asc).
							map{|bvc|
								if bvc.subject?
									bvc.source_video.donor.nil? ? bvc.source_video.video.path : bvc.source_video.donor.video.path
								else
									bvc.dynamic_aae_project.rendered_video.path
								end
							}.reject(&:blank?)
						output = VideoTools::VideoBlender.new(videos: video_files).blend()
						blended_video.file = output
						blended_video.save!
						blended_video.reload
					rescue Exception => e
						raise e
					ensure
						output.try(:close)
						unless output.blank?
							FileUtils.rm_rf output
						end
					end
				end
			end
		end

		def max_attempts
			self.class.get_max_attempts
		end

		def max_run_time
			240 #seconds
		end

		def reschedule_at(current_time, attempts)
			current_time + 10.minutes
		end

		def self.get_max_attempts
			5
		end
	end
end
