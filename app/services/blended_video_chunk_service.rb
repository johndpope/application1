class BlendedVideoChunkService
	class << self
		def replace_rejected_chunks

		end

		def reject_chunk(chunk_id)
			blended_video_chunk = BlendedVideoChunk.find(chunk_id)
			blended_video_chunk.accepted = false
			blended_video_chunk.accepted_automatically = true
			blended_video_chunk.save!
		end

		def replace_chunk(chunk_id, rendering_machine_id)
			ActiveRecord::Base.transaction do
				#check if delayed job is not already created
				Delayed::Job.where(queue: DelayedJobQueue::TEMPLATES_DYNAMIC_AAE_PROJECT_REPLACE).
					where("handler like E'%blended_video_chunk_id: ?\n%'", chunk_id).delete_all
				Delayed::Job.enqueue Templates::DynamicAaeProjects::ReplaceDynamicAaeProjectJob.new(chunk_id,rendering_machine_id),
					queue: DelayedJobQueue::TEMPLATES_DYNAMIC_AAE_PROJECT_REPLACE
			end
		end
	end
end
