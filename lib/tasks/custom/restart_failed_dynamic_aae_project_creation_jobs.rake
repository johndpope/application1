namespace :templates do
	namespace :dynamic_aae_projects do
		task restart_failed_creation_jobs: :environment do
			max_attempts = 5
			in_queue = 40
			RenderingMachine.where(is_active: true).
				where(is_accessible: true).
				where("in_queue < ?", in_queue).
				where(in_watch_folder: 0).each do |rm|
					jobs_count = Delayed::Job.where("handler like '%CreateDynamicAaeProjectJob%'").
						where("handler like E'%rendering_machine_id: ?\n%'",rm.id).
						where("last_error NOT LIKE '%Not enough%'").
						where("attempts BETWEEN 0 AND ?", (max_attempts-1)).count
					if jobs_count < in_queue && !rm.available_disk_space.nil? && rm.available_disk_space > 1.gigabyte
						Delayed::Job.
							where("handler like '%CreateDynamicAaeProjectJob%'").
							where("handler like E'%rendering_machine_id: ?\n%'",rm.id).							
							where(attempts: max_attempts).
							where("created_at < '2017-03-20 18:00:00'").
							order(:updated_at).
							limit(in_queue-jobs_count).each do |dj|
								DelayedJobService.restart_job dj.id
						end
					end
			end
		end
	end
end
