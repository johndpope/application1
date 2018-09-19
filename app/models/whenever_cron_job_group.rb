class WheneverCronJobGroup < ActiveRecord::Base
	has_many :jobs, class_name: 'WheneverCronJob', foreign_key: 'job_group_id', dependent: :nullify
	validates_presence_of :name
	validates_uniqueness_of :name, case_sensitive: false
end
