require 'net/ftp'
module Templates
	module DynamicAaeProjects
		RemoveOutputVideoFromRenderingMachineJob = Struct.new(:dynamic_aae_project_id) do
			def perform
				ActiveRecord::Base.transaction do
					dynamic_aae_project = Templates::DynamicAaeProject.find(dynamic_aae_project_id)

					unless dynamic_aae_project.rendered_video.blank?
						ftp = dynamic_aae_project.rendering_machine.ftp_connection
						ftp.chdir(dynamic_aae_project.rendering_machine.ftp_watch_folder_output_dir)
						file_list = ftp.nlst('*.mp4')
						file_list.each do |f|
							video_file_extension = File.extname(f)
							video_file_name = File.basename(f,video_file_extension)
							parts = video_file_name.split('_')
							daaep_parts = parts[2]
							if daaep_id = daaep_parts.split('-')[1]
								if dynamic_aae_project.id == daaep_id.to_i
									ftp.delete(f)
								end
							end
						end
						ftp.close
					end
				end
			end

			def max_attempts
	      25
	    end

			def max_run_time
				120 #seconds
			end

			def reschedule_at(current_time, attempts)
	      current_time + 10.minutes
	    end
		end
	end
end
