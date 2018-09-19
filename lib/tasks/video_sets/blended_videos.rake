namespace :blended_videos do
	task :random_blended_video, [:rendering_machine_id, :client_id] => :environment do |t, args|
		client = Client.find(args['client_id'])
		rendering_machine = RenderingMachine.find(args['rendering_machine_id'])
		BlendedVideoService.create_random_blended_video rendering_machine, client
	end

	task :random_blended_videos, [:rendering_machine_id, :client_id, :count] => :environment do |t, args|
		client = Client.find(args['client_id'])
		rendering_machine = RenderingMachine.find(args['rendering_machine_id'])
		count = args['count'].blank? ? 1 : args['count'].to_i
		begin
			1.upto(count){BlendedVideoService.create_random_blended_video rendering_machine, client}
		rescue Exception => e
			puts e.message
		end
	end

	task approve_completed_video_sets: :environment do |t, args|
		BlendedVideo.
			joins("LEFT OUTER JOIN youtube_videos ON youtube_videos.blended_video_id = blended_videos.id").
			where("youtube_videos.id" => nil).
			joins(:rendering_settings).
			where("blended_video_completed_unreviewed(blended_videos.id)::int = 1").
			where('client_rendering_settings.auto_approve_rendered_video_chunks' => true).
			find_in_batches(batch_size: 100) do |batch|
			batch.each do |bv|
				BlendedVideoService.approve(bv.id)
			end
		end
	end

	task :blend_accepted_videos => :environment do |t, args|
		BlendedVideo.unscoped.
			joins(:rendering_settings).
			where('client_rendering_settings.auto_blend_accepted_video_sets' => true).
			joins("LEFT OUTER JOIN youtube_videos ON youtube_videos.blended_video_id = blended_videos.id").
			where("youtube_videos.id" => nil).
			where('blended_video_accepted(blended_videos.id)::int = 1 AND file_file_name IS NULL').
			find_in_batches(batch_size: 100) do |batch|
				batch.each do |bv|
					unless Delayed::Job.where(queue: DelayedJobQueue::BLEND_VIDEO_SET).
						where("handler like ?","%blended_video_id: #{bv.id}\n%").exists?
						Delayed::Job.enqueue BlendedVideos::BlendVideoSetJob.new(bv.id),
							queue: DelayedJobQueue::BLEND_VIDEO_SET
					end
				end
		end
	end

	task :force_blend, [:blended_video_id] => :environment do |t, args|
		unless Delayed::Job.where(queue: DelayedJobQueue::BLEND_VIDEO_SET).
			where("handler like ?","%blended_video_id: #{bv.id}\n%").exists?
			Delayed::Job.enqueue BlendedVideos::ForceBlendJob.new(args['blended_video_id'].to_i),
				queue: DelayedJobQueue::FORCE_BLEND_VIDEO_SET
		end
	end

	task delete_posted_videos: :environment do |t, args|
		YoutubeVideo.
			joins(:blended_video).
			where(is_active: true).
			where(ready: true).
			where.not(youtube_video_id: nil).
			where.not("blended_videos.file_file_name" => nil).
			readonly(false).
			find_in_batches(batch_size: 100) do |batch|
				ActiveRecord::Base.transaction do
					batch.each do |yv|
						yv.video = nil
						yv.blended_video.file = nil
						yv.blended_video.save!
						yv.save!
					end
				end
			end
	end

	task sync_workflow_status: :environment do |t,args|
		BlendedVideo.joins(:client).
			joins(:blended_video_workflow_status).
			where("clients.is_active IS TRUE").
			where("(blended_video_workflow_statuses.workflow_status->'youtube_video_posted') IS NULL OR blended_video_workflow_statuses.workflow_status->>'youtube_video_posted' != 'true'").
			readonly(false).find_in_batches(batch_size: 100) do |batch|
				batch.each do |bv|
					bvws = BlendedVideoWorkflowStatus.where(blended_video_id: bv.id).first_or_create
					bvws.update_attributes! workflow_status: bv.build_workflow_status
				end
		end
	end
end
