class WheneverCronJob < ActiveRecord::Base
	belongs_to :job_group, class_name: 'WheneverCronJobGroup', foreign_key: 'job_group_id'
	validates_presence_of :job_type
	validates_presence_of :job_value
	validates_presence_of :period
	validates_presence_of :description

	extend Enumerize
	JOB_TYPES = {command: 1, runner: 2, rake: 3}
	enumerize :job_type, in: JOB_TYPES

	def self.valid_jobs
		where("job_value IS NOT NULL AND job_value != ''").
		where("period IS NOT NULL AND period != ''").
		where.not(job_type: nil)
	end
end
