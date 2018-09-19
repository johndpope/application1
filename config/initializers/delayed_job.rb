Delayed::Worker.delay_jobs = !Rails.env.test?
Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.max_attempts = 5
#Delayed::Worker.logger ||= Logger.new(Rails.root.join('log', 'delayed_job.log'), 10, 500.megabytes)
