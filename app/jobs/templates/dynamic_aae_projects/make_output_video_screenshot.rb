module Templates
	module DynamicAaeProjects
		MakeOutputVideoScreenshotJob = Struct.new(:dynamic_aae_project_id) do
			def perform
				ActiveRecord::Base.transaction do
					dynamic_aae_project = Templates::DynamicAaeProject.find dynamic_aae_project_id

				end
			end

			def max_attempts
	      5
	    end

	    def reschedule_at(current_time, attempts)
	      current_time + 10.minutes
	    end

			def success(job)

			end
		end
	end
end
