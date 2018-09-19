namespace :jdrf do
	task replace_rejected_chunks: :environment do
		client_id = 7
		limit = 10

		scope = BlendedVideoChunk.
			joins(:blended_video).
			joins("INNER  JOIN source_videos ON source_videos.id=blended_videos.source_id").
			joins("INNER JOIN products ON products.id=source_videos.product_id").
			where("products.client_id" => client_id).
			where(accepted: false).
			without_chunk_type(:subject)

		if scope.exists?
			RenderingMachine.where("is_active IS TRUE AND is_test IS NOT TRUE").each do |rendering_machine|
				unless Delayed::Job.where("(queue = ? OR queue = ?) AND handler like ? AND attempts = 0",
					DelayedJobQueue::TEMPLATES_DYNAMIC_AAE_PROJECT_CREATE,
					DelayedJobQueue::TEMPLATES_DYNAMIC_AAE_PROJECT_REPLACE,
					"%rendering_machine_id: #{rendering_machine.id}\n%").exists?
					puts "Processing Rendering Machine # #{rendering_machine.id} ..."
					rendering_machine_info = RenderingMachineService.get_info(rendering_machine.id)
					if !rendering_machine_info[:in_watch_folder].blank? &&
						!rendering_machine_info[:in_queue].blank? &&
						rendering_machine_info[:in_watch_folder] == 0 &&
						rendering_machine_info[:in_queue] == 0
						1.upto(limit) do
							if random_chunk = scope.order('RANDOM()').first
								unless Delayed::Job.where("(queue = ? OR queue = ?) AND handler like ?",
									DelayedJobQueue::TEMPLATES_DYNAMIC_AAE_PROJECT_CREATE,
									DelayedJobQueue::TEMPLATES_DYNAMIC_AAE_PROJECT_REPLACE,
									"%blended_video_chunk_id: #{rendering_machine.id}\n%").exists?
									Delayed::Job.enqueue Templates::DynamicAaeProjects::ReplaceDynamicAaeProjectJob.new(random_chunk.id,
										rendering_machine.id), queue: DelayedJobQueue::TEMPLATES_DYNAMIC_AAE_PROJECT_REPLACE
								end
							end
						end
					end
				end
			end
		end
	end
end
