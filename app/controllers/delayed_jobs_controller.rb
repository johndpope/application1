class DelayedJobsController < ApplicationController
	def relaunch()
		Delayed::Job.find(params[:id]).invoke_job
	end
end
