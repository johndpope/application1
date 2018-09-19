module DelayedJobService
	def self.restart_job(delayed_job_id)
		delayed_job = Delayed::Job.find(delayed_job_id)
		delayed_job.attempts = 0
		delayed_job.run_at = Time.now
		%w(last_error failed_at locked_at locked_by failed_at).each{
			|f| delayed_job.send("#{f}=", nil)
		}
		delayed_job.save!
	end

	def self.kill_job(delayed_job_id)
		Delayed::Job.find(delayed_job_id).delete
	end
end
