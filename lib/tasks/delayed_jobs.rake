namespace :delayed_jobs do
	# lib/tasks/restart_job.rake
	desc 'Restarts Delayed Job by particular ID'
	task :restart_job, [:delayed_job_id] => :environment do |t, args|
		DelayedJobService.restart_job(args['delayed_job_id'])
	end

	# lib/tasks/kill_job.rake
	desc 'Kills Delayed Job by particular ID'
	task :kill_job, [:delayed_job_id] => :environment do |t, args|
		DelayedJobService.kill_job(args['delayed_job_id'])
	end
end
