require 'net/ftp'
module Templates
	module DynamicAaeProjects
		TakeOutputVideoJob = Struct.new(:dynamic_aae_project_id) do
			def perform
				ActiveRecord::Base.transaction do
					tmp_output_video_base_dir = "/tmp/broadcaster/aae_templates/output_videos"
					FileUtils.mkdir_p tmp_output_video_base_dir
					dynamic_aae_project = Templates::DynamicAaeProject.find(dynamic_aae_project_id)

					if dynamic_aae_project.rendering_machine.blank?
						raise "Rendering Machine for Dynamic AAE Project with ID #{dynamic_aae_project_id} was not set"
					end

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
								begin
									tmp_output_video_filename = "#{SecureRandom.uuid}.mp4"
									tmp_output_video_filepath = File.join(tmp_output_video_base_dir, tmp_output_video_filename)
									ftp.getbinaryfile(f, tmp_output_video_filepath, 1024)
									f = open(tmp_output_video_filepath, "r")
									dynamic_aae_project.rendered_video = f
									dynamic_aae_project.save!
									f.close
								rescue Exception => e
									puts e.message
									puts e.backtrace.inspect
									raise e
								ensure
									FileUtils.rm_f tmp_output_video_filepath
								end
								break;
							end
						end
					end
					ftp.close
				end
			end

			def max_attempts
	      25
	    end

			def max_run_time
				300 #seconds
			end

	    def reschedule_at(current_time, attempts)
	      current_time + 5.minutes
	    end

			def success(job)
				ActiveRecord::Base.transaction do
					dynamic_aae_project = Templates::DynamicAaeProject.find(dynamic_aae_project_id)
					unless dynamic_aae_project.rendered_video.blank?
						dynamic_aae_project.is_rendered = true
						dynamic_aae_project.save!
					end

					Delayed::Job.enqueue Templates::DynamicAaeProjects::RemoveOutputVideoFromRenderingMachineJob.new(dynamic_aae_project_id),
						queue: DelayedJobQueue::RENDERING_MACHINE_REMOVE_OUTPUT_VIDEO
				end
			end
		end
	end
end
