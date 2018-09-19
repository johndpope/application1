require 'net/ftp'
module Templates
	module DynamicAaeProjects
		GenerateTestProjectJob = Struct.new(:client_id,
			:product_id,
			:source_video_id,
			:location_id,
			:location_type,
			:aae_template_id,
			:dynamic_aae_project_id,
			:rendering_machine_id) do
			def perform
				ActiveRecord::Base.transaction do
					client = Client.find(client_id)
					product = Product.find(product_id)
					subject_video = SourceVideo.find(source_video_id)
					location = location_type.constantize.find(location_id)
					aae_template = Templates::AaeProject.find(aae_template_id)
					dynamic_aae_project = Templates::AaeProjectGenerator.new(location: location,
						target: 'test',
						client: client,
						product: product,
						source_video: subject_video,
						aae_project: aae_template,
						dynamic_aae_project_id: dynamic_aae_project_id).generate
					dynamic_aae_project.rendering_machine_id = rendering_machine_id
					dynamic_aae_project.is_created = true
					dynamic_aae_project.save!
				end
			end

			def max_attempts
	      get_max_attempts
	    end

			def max_run_time
				900 #seconds
			end

	    def reschedule_at(current_time, attempts)
	      current_time + 20.minutes
	    end

			def success(job)
				rendering_machine = RenderingMachine.find(rendering_machine_id)
				dynamic_aae_project = Templates::DynamicAaeProject.find(dynamic_aae_project_id)
				ftp = Net::FTP.new
				begin
					ftp.connect(rendering_machine.ip)
					ftp.passive = true
					ftp.login(rendering_machine.user, rendering_machine.password)
					ftp.chdir(rendering_machine.ftp_broadcaster_aae_projects_dir)
					ftp.putbinaryfile(dynamic_aae_project.tar_project.path)

					ActiveRecord::Base.transaction do
						dynamic_aae_project.is_transmitted = true
						unless dynamic_aae_project.target.test?
							dynamic_aae_project.tar_project = nil;
						end
						dynamic_aae_project.save!
					end
				rescue Exception => e
					raise e
				ensure
					begin; rescue Exception => ex; ftp.close; end
				end
			end

			def self.get_max_attempts
				5
			end
		end
	end
end
