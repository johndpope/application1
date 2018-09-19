require 'net/ftp'
module Templates
	module DynamicAaeProjects
		CreateDynamicAaeProjectJob = Struct.new(:client_id,
			:product_id,
			:source_video_id,
			:location_id,
			:location_type,
			:aae_project_id,
			:target,
			:rendering_machine_name,
			:rendering_machine_id,
			:blended_video_chunk_id) do
			def perform
				ActiveRecord::Base.transaction do
					client = Client.find(client_id)
					product = Product.find(product_id)
					subject_video = SourceVideo.find(source_video_id)
					location = location_type.constantize.find(location_id)
					aae_project = Templates::AaeProject.find(aae_project_id)
					track_attributions = true
					rendering_machine = RenderingMachine.find(rendering_machine_id)
					blended_video_chunk = BlendedVideoChunk.find(blended_video_chunk_id)

					dynamic_aae_project = Templates::AaeProjectGenerator.new(location: location,
						target: 'distribution',
						client: client,
						product: product,
						source_video: subject_video,
						aae_project: aae_project,
						blended_video_chunk_id: blended_video_chunk_id).generate
					dynamic_aae_project.rendering_machine_id = rendering_machine_id
					dynamic_aae_project.is_created = true
					dynamic_aae_project.save!
					blended_video_chunk = BlendedVideoChunk.find(blended_video_chunk_id)
					blended_video_chunk.templates_dynamic_aae_project_id = dynamic_aae_project.id
					blended_video_chunk.accepted = nil
					blended_video_chunk.accepted_automatically = nil
					blended_video_chunk.save!
				end
			end

			def max_attempts
	      self.class.get_max_attempts
	    end

			def max_run_time
				900 #seconds
			end

	    def reschedule_at(current_time, attempts)
	      current_time + 20.minutes
	    end

			def success(job)
				rendering_machine = RenderingMachine.find(rendering_machine_id)
				blended_video_chunk = BlendedVideoChunk.find(blended_video_chunk_id)
				ftp = Net::FTP.new
				begin
					ftp.connect(rendering_machine.ip)
					ftp.passive = true
					ftp.login(rendering_machine.user, rendering_machine.password)
					ftp.chdir(rendering_machine.ftp_broadcaster_aae_projects_dir)
					ftp.putbinaryfile(blended_video_chunk.dynamic_aae_project.tar_project.path)
					unless blended_video_chunk.dynamic_aae_project.nil?
						ActiveRecord::Base.transaction do
							blended_video_chunk.dynamic_aae_project.is_transmitted = true
							unless blended_video_chunk.dynamic_aae_project.target.test?
								blended_video_chunk.dynamic_aae_project.tar_project = nil;
							end
							blended_video_chunk.dynamic_aae_project.save!
							blended_video_chunk.save!
						end
					end
				rescue Exception => e
					raise e
				ensure
					ftp.close
				end
			end

			def self.get_max_attempts
				5
			end
		end
	end
end
