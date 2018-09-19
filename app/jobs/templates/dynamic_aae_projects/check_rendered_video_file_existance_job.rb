module Templates
	module DynamicAaeProjects
		CheckRenderedVideoFileExistanceJob = Struct.new(:dynamic_aae_project_id) do
			def perform
				ActiveRecord::Base.transaction do
					if dynamic_aae_project = Templates::DynamicAaeProject.
						where(id: dynamic_aae_project_id).
						where(rendered_video_file_exists: nil).
						where.not(rendered_video_file_name: nil).first
						exists = File.exists? dynamic_aae_project.rendered_video.path.to_s
						dynamic_aae_project.update_attributes!(rendered_video_file_exists: exists)
					end
				end
			end

			def max_attempts
	      2
	    end

			def max_run_time
				120 #seconds
			end

	    def reschedule_at(current_time, attempts)
	      current_time + 5.minutes
	    end

			def success(job)

			end
		end
	end
end
