namespace :jdrf do
	namespace :blended_videos do
		task schedule_missing_credits: :environment do
			client_id = 7
			credits_limit = 10
			blended_videos_with_media_credits = BlendedVideoChunk.
				joins(:blended_video).
				joins("INNER JOIN source_videos on source_videos.id = blended_videos.source_id").
				joins("INNER JOIN products on products.id = source_videos.product_id").
				with_chunk_type(:credits).
				where("products.client_id = ?", client_id).pluck(:blended_video_id).uniq
			if BlendedVideo.where.not(id: blended_videos_with_media_credits).exists?
				RenderingMachine.where("is_active IS TRUE AND is_test IS NOT TRUE").each do |rendering_machine|
					unless Delayed::Job.where("(queue = ? OR queue = ?) AND handler like '%rendering_machine_id: ?\n%' AND attempts = 0",
						DelayedJobQueue::TEMPLATES_DYNAMIC_AAE_PROJECT_CREATE,
						DelayedJobQueue::TEMPLATES_DYNAMIC_AAE_PROJECT_REPLACE,
						rendering_machine.id).exists?
						puts "Processing Rendering Machine # #{rendering_machine.id} ..."
						rendering_machine_info = RenderingMachineService.get_info(rendering_machine.id)
						if !rendering_machine_info[:in_watch_folder].blank? &&
							!rendering_machine_info[:in_queue].blank? &&
							rendering_machine_info[:in_watch_folder] == 0 &&
							rendering_machine_info[:in_queue] == 0
							1.upto(credits_limit) do
								if blended_video = BlendedVideo.where.not(id: blended_videos_with_media_credits).order('random()').first
									random_credits_template = Templates::AaeTemplateService.random_template('credits',client_id)
									ActiveRecord::Base.transaction do
										blended_video_chunk = BlendedVideoChunk.create! blended_video_id: blended_video.id,
											order_nr: (blended_video.blended_video_chunks.count+1),
											chunk_type: 'credits'
										Delayed::Job.enqueue Templates::DynamicAaeProjects::CreateDynamicAaeProjectJob.new(blended_video.source_video.client.id,
											blended_video.source_video.product.id,
											blended_video.source_video.id,
											blended_video.location_id,
											blended_video.location_type,
											random_credits_template.id,
											'distribution',
											rendering_machine.name,
											rendering_machine.id,
											blended_video_chunk.id), queue: DelayedJobQueue::TEMPLATES_DYNAMIC_AAE_PROJECT_CREATE
									end
								end
							end
						end
					end
				end
			end
		end
	end
end
