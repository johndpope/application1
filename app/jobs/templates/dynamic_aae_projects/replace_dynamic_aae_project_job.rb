module Templates
	module DynamicAaeProjects
		ReplaceDynamicAaeProjectJob = Struct.new(:blended_video_chunk_id, :rendering_machine_id) do
				def perform
					ActiveRecord::Base.transaction do
						blended_video_chunk = BlendedVideoChunk.find(blended_video_chunk_id)
						aae_project = Templates::AaeTemplateService.random_template(blended_video_chunk.chunk_type, blended_video_chunk.blended_video.source_video.client.id)
						rendering_machine = (defined?(rendering_machine_id)).nil? ? RenderingMachine.where(is_active: true).order('RANDOM()').first : RenderingMachine.where(id: rendering_machine_id, is_active: true).first
						if rendering_machine.nil?
							raise "There is no rendering machine active to replace dynamic project for blended video chunk with ID=#{blended_video_chunk.id}"
						end
            # Templates::DynamicAaeProject.find_by_id(blended_video_chunk.templates_dynamic_aae_project_id) was causing this:  /home/broadcaster/broadcaster/shared/bundle/ruby/2.1.0/gems/activerecord-4.0.0/lib/active_record/attribute_methods/read.rb:56: warning: redefining `object_id' may cause serious problems
						if dynamic_aae_project = Templates::DynamicAaeProject.where(id: blended_video_chunk.templates_dynamic_aae_project_id).first
							dynamic_aae_project.destroy!
						end
						Delayed::Job.enqueue Templates::DynamicAaeProjects::CreateDynamicAaeProjectJob.new(blended_video_chunk.blended_video.source_video.client.id,
							blended_video_chunk.blended_video.source_video.product.id,
							blended_video_chunk.blended_video.source_video.id,
							blended_video_chunk.blended_video.location_id,
							blended_video_chunk.blended_video.location_type,
							aae_project.id,
							'distribution',
							rendering_machine.name,
							rendering_machine.id,
							blended_video_chunk_id), queue: DelayedJobQueue::TEMPLATES_DYNAMIC_AAE_PROJECT_CREATE
						blended_video_chunk.accepted = nil
						blended_video_chunk.accepted_automatically = nil
						blended_video_chunk.save!
					end
				end

				def max_attempts
		      get_max_attempts
		    end

				def max_run_time
					120 #seconds
				end

		    def reschedule_at(current_time, attempts)
		      current_time + 20.minutes
		    end

				def self.get_max_attempts
					5
				end
		end
	end
end
