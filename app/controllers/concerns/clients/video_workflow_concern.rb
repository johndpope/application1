extend ActiveSupport::Concern
module Clients
	module VideoWorkflowConcern
		def dj_segment_generation_scope(client_id, blended_video_chunk_ids: nil, only_failed_jobs: false)
			coalesce_part = "COALESCE(NULLIF(substring(handler, E'blended_video_chunk_id: (.*?)\n'),''),'0')::integer"
			wheres = ["clients.id = #{client_id}"]
			wheres << "queue = '#{DelayedJobQueue::TEMPLATES_DYNAMIC_AAE_PROJECT_CREATE}' OR queue = '#{DelayedJobQueue::TEMPLATES_DYNAMIC_AAE_PROJECT_REPLACE}'"
			wheres << "attempts > 0" if only_failed_jobs
			wheres << "#{coalesce_part} = ANY(Array[#{blended_video_chunk_ids.to_a.join(',')}]::integer[])" if blended_video_chunk_ids.to_a.any?
			Delayed::Job.
				select(["#{coalesce_part} AS blended_video_chunk_id", "blended_videos.id AS blended_video_id", "delayed_jobs.*"]).
				joins("INNER JOIN blended_video_chunks ON #{coalesce_part} = blended_video_chunks.id").
				joins("INNER JOIN blended_videos ON blended_video_chunks.blended_video_id = blended_videos.id").
				joins("INNER JOIN source_videos ON blended_videos.source_id = source_videos.id").
				joins("INNER JOIN products ON source_videos.product_id = products.id").
				joins("INNER JOIN clients ON products.client_id = clients.id").
				where(wheres.map{|w|"(#{w})"}.to_a.join(' AND '))
		end

		def dj_segment_blending_scope(client_id, blended_video_ids: nil, only_failed_jobs: false)
			coalesce_part = "COALESCE(NULLIF(substring(handler, E'blended_video_id: (.*?)\n'),''),'0')::integer"
			wheres = ["clients.id = #{client_id}"]
			wheres << "queue = '#{DelayedJobQueue::BLEND_VIDEO_SET}' OR queue = '#{DelayedJobQueue::FORCE_BLEND_VIDEO_SET}'"
			wheres << "attempts > 0" if only_failed_jobs
			wheres << "#{coalesce_part} = ANY(Array[#{blended_video_ids.to_a.join(',')}]::integer[])" if blended_video_ids.to_a.any?
			Delayed::Job.
				select(["#{coalesce_part} AS blended_video_id", "delayed_jobs.*"]).
				joins("INNER JOIN blended_videos ON blended_videos.id = #{coalesce_part}").
				joins("INNER JOIN source_videos ON blended_videos.source_id = source_videos.id").
				joins("INNER JOIN products ON source_videos.product_id = products.id").
				joins("INNER JOIN clients ON products.client_id = clients.id").
				where(wheres.map{|w|"(#{w})"}.to_a.join(' AND '))
		end

		def dj_youtube_video_content_creation_scope(client_id, blended_video_ids: nil, only_failed_jobs: false)
			coalesce_part = "COALESCE(NULLIF(substring(handler, E'blended_video_id: (.*?)\n'),''),'0')::integer"
			wheres = ["clients.id = #{client_id}"]
			wheres << "queue = '#{DelayedJobQueue::YOUTUBE_CREATE_VIDEO}'"
			wheres << "attempts > 0" if only_failed_jobs
			wheres << "#{coalesce_part} = ANY(Array[#{blended_video_ids.to_a.join(',')}]::integer[])" if blended_video_ids.to_a.any?
			Delayed::Job.
				select(["#{coalesce_part} AS blended_video_id", "delayed_jobs.*"]).
				joins("INNER JOIN blended_videos ON blended_videos.id = #{coalesce_part}").
				joins("INNER JOIN source_videos ON blended_videos.source_id = source_videos.id").
				joins("INNER JOIN products ON source_videos.product_id = products.id").
				joins("INNER JOIN clients ON products.client_id = clients.id").
				where(wheres.map{|w|"(#{w})"}.to_a.join(' AND '))
		end

		def dj_youtube_video_thumbnail_creation_scope(client_id, youtube_video_ids: nil, only_failed_jobs: false)
			coalesce_part = "COALESCE(NULLIF(substring(handler, E'youtube_video_id: (.*?)\n'),''),'0')::integer"
			wheres = ["clients.id = #{client_id}"]
			wheres << "queue = '#{DelayedJobQueue::YOUTUBE_CREATE_VIDEO_THUMBNAIL_FOR_GENERATED_VIDEO}'"
			wheres << "attempts > 0" if only_failed_jobs
			wheres << "#{coalesce_part} = ANY(Array[#{youtube_video_ids.to_a.join(',')}]::integer[])" if youtube_video_ids.to_a.any?
			Delayed::Job.
				select(["delayed_jobs.*","#{coalesce_part} AS youtube_video_id", "blended_videos.id AS blended_video_id"]).
				joins("LEFT OUTER JOIN youtube_videos ON youtube_videos.id = COALESCE(substring(handler, E'youtube_video_id: (.*?)\n'),'0')::integer").
				joins("LEFT OUTER JOIN blended_videos ON blended_videos.id = youtube_videos.blended_video_id").
				joins("INNER JOIN source_videos ON blended_videos.source_id = source_videos.id").
				joins("INNER JOIN products ON source_videos.product_id = products.id").
				joins("INNER JOIN clients ON products.client_id = clients.id").
				where(wheres.map{|w|"(#{w})"}.to_a.join(' AND '))
		end
	end
end
