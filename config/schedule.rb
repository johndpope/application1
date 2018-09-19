# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

require File.expand_path('../environment', __FILE__)
set :environment, Rails.env.to_sym

::WheneverCronJob.valid_jobs.where(is_active: true).each do |job|
	period = job.period =~ /(\d+).(minute|hour|day|year|month)/ ? eval(job.period) : job.period
	at = job.at.blank? ? nil : job.at
	every period, at: at do
		send(job.job_type, job.job_value)
	end
end
