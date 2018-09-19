namespace :rendering_machines do
	task :schedule_video_sets => :environment do |t, args|
		number_of_video_sets = 2

		if client = Client.
			joins(:rendering_settings).
			where("clients.is_active IS TRUE").
			where("video_workflow_client_has_subject_videos_for_render(clients.id) IS TRUE").
			order("client_rendering_settings.rendering_priority ASC, clients.name ASC").
			first

				RenderingMachine.where("is_active IS TRUE AND is_test IS NOT TRUE").each do |rendering_machine|
					unless Delayed::Job.where("(queue = ? OR queue = ?) AND handler like '%rendering_machine_id: ?\n%' AND attempts = 0",
						DelayedJobQueue::TEMPLATES_DYNAMIC_AAE_PROJECT_CREATE,
						DelayedJobQueue::TEMPLATES_DYNAMIC_AAE_PROJECT_REPLACE,
						rendering_machine.id).exists?
							ActiveRecord::Base.transaction do
								RenderingMachineService.schedule_video_sets(rendering_machine.id, client.id, number_of_video_sets)
							end
					end
				end
		end
	end

	task :schedule_video_sets_for_rm, [:rendering_machine_id, :client_id, :count] => :environment do |t, args|
		ActiveRecord::Base.transaction do
			rendering_machine = RenderingMachine.find(args['rendering_machine_id'])
			raise 'Rendering Machine has status "inactive"' unless rendering_machine.is_active?

			if Delayed::Job.where("(queue = ? OR queue = ?) AND handler like '%rendering_machine_id: ?\n%' AND attempts = 0",
				DelayedJobQueue::TEMPLATES_DYNAMIC_AAE_PROJECT_CREATE,
				DelayedJobQueue::TEMPLATES_DYNAMIC_AAE_PROJECT_REPLACE,
				rendering_machine.id).exists?
				puts "Cannot schedule new video sets for this rendering machine while another video sets are already scheduled"
			else
				puts "Processing Rendering Machine # #{rendering_machine.id} ..."
				RenderingMachineService.schedule_video_sets(rendering_machine.id, args['client_id'].to_i, args['count'].to_i)
			end
		end
	end

	task :get_infos => :environment do |t, args|
		statuses = RenderingMachineService.get_infos
		statuses.each do |key, value|
			puts "id: %3{id} | is_accessible: %5{is_accessible} | in_watch_folder: %4{in_watch_folder} | in_queue: %4{in_queue} | outputs: %4{outputs}" % {id: key, is_accessible: value[:is_accessible], in_watch_folder: (value[:in_watch_folder] || '?'), in_queue: (value[:in_queue] || '?'), outputs:(value[:in_watch_folder_output] || '?')}
		end
	end

	task :sync_infos => :environment do |t, args|
		RenderingMachineService.sync_infos
	end

	task :take_output_videos => :environment do |t,args|
		Templates::DynamicAaeProject.
			where.not(rendering_machine_id: nil).
			where("is_rendered IS NULL").
			find_in_batches(batch_size: 100) do |batch|
				ActiveRecord::Base.transaction do
					batch.each do |rvc|
						#check if delayed job is not already created
						unless Delayed::Job.where(queue: DelayedJobQueue::RENDERING_MACHINE_TAKE_OUTPUT_VIDEO).
							where("handler like ?", "%dynamic_aae_project_id: #{rvc.id}\n%").exists?
							Delayed::Job.enqueue Templates::DynamicAaeProjects::TakeOutputVideoJob.new(rvc.id),
								queue: DelayedJobQueue::RENDERING_MACHINE_TAKE_OUTPUT_VIDEO
						end
					end
				end
			end
	end

	task :take_output_videos_from_rendering_machine, [:rendering_machine_id] => :environment do |t, args|
		rendering_machine = RenderingMachine.find(args['rendering_machine_id'])
		Templates::DynamicAaeProject.
			where(rendering_machine_id: rendering_machine.id).
			where("is_rendered IS NULL").
			find_in_batches(batch_size: 100) do |batch|
				ActiveRecord::Base.transaction do
					batch.each do |rvc|
						#check if delayed job is not already created
						unless Delayed::Job.where(queue: DelayedJobQueue::RENDERING_MACHINE_TAKE_OUTPUT_VIDEO).
							where("handler like ?", "%dynamic_aae_project_id: #{rvc.id}\n%").exists?
							Delayed::Job.enqueue Templates::DynamicAaeProjects::TakeOutputVideoJob.new(rvc.id),
								queue: DelayedJobQueue::RENDERING_MACHINE_TAKE_OUTPUT_VIDEO
						end
					end
				end
			end
	end

	task :take_media_encoder_logs => :environment do |t, args|
		ActiveRecord::Base.transaction do
			RenderingMachine.where.not(is_active: false).to_a.each do |rm|
				#check if delayed job is not already created
				unless Delayed::Job.where("handler like '%SyncMediaEncoderLogJob%' and handler like ?", "%rendering_machine_id: #{rm.id}\n%").exists?
					Delayed::Job.enqueue Templates::DynamicAaeProjects::SyncMediaEncoderLogJob.new(rm.name, rm.id),
						queue: DelayedJobQueue::RENDERING_MACHINE_SYNC_AME_LOG
				end
			end
		end
	end
end
