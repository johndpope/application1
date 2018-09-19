require 'net/ftp'
module Templates
	module DynamicAaeProjects
		class GenericProjectGenerationJob
			class << self
				def register_job
					return (Struct.new(:dynamic_aae_project_id) do
						def perform
							target_range = Templates::DynamicAaeProject::TARGETS.keys.map{|k|k.to_s}
							dynamic_aae_project = Templates::DynamicAaeProject.find(dynamic_aae_project_id)
							raise "target in Dynamic AAE Project instance cannot be NULL" if dynamic_aae_project.target.nil?
							raise "target in Dynamic AAE Project instance must be in range [#{target_range.join(',')}}]" unless target_range.include?(dynamic_aae_project.target)
							raise "rendering_machine_id in Dynamic AAE Project instance cannot be NULL" if dynamic_aae_project.rendering_machine_id.nil?

							ActiveRecord::Base.transaction do
								unless dynamic_aae_project.tar_project.present?
									begin
										Templates::DynamicAaeProjects::ProjectGenerationService.generate_content(dynamic_aae_project_id)
										dynamic_aae_project.is_created = true
									rescue Exception => e
										dynamic_aae_project.is_created = false
										raise e
									ensure
										dynamic_aae_project.save!
									end
								end
							end
						end

						def max_attempts
				      self.class.get_max_attempts
				    end

						def max_run_time
							self.class.get_max_run_time
						end

				    def reschedule_at(current_time, attempts)
				      current_time + self.class.get_reschedule_time
				    end

						def success(job)
							dynamic_aae_project = Templates::DynamicAaeProject.find(dynamic_aae_project_id)
							raise "TAR archive doesn't exist" unless dynamic_aae_project.tar_project.present?

							ftp = Net::FTP.new
							begin
								ftp.connect(dynamic_aae_project.rendering_machine.ip)
								ftp.passive = true
								ftp.login(dynamic_aae_project.rendering_machine.user, dynamic_aae_project.rendering_machine.password)
								ftp.chdir(dynamic_aae_project.rendering_machine.ftp_broadcaster_aae_projects_dir)
								ftp.putbinaryfile(dynamic_aae_project.tar_project.path)

								ActiveRecord::Base.transaction do
									dynamic_aae_project.is_transmitted = true
									dynamic_aae_project.tar_project = nil unless dynamic_aae_project.target.test?
									dynamic_aae_project.save!
								end
							rescue Exception => e
								dynamic_aae_project.update_attributes! is_transmitted: false
								raise e
							ensure
								ftp.close
							end
						end

						class << self
							def get_max_attempts
								5
							end

							def get_reschedule_time
								20.minutes
							end

							def get_max_run_time
								900 #seconds
							end

							def get_queue_name
								name.underscore.gsub('/','_')
							end
						end
					end)
				end
			end
		end
	end
end
