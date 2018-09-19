namespace :blended_video_chunks do
	desc 'Reject blended Video Chunk by ID'
	task :reject_chunk, [:chunk_id] => :environment do |t, args|
		BlendedVideoChunkService.reject_chunk args['chunk_id']
	end

	desc 'Replace Dynamic AAE Project associated with specific video chunk'
	task :replace_chunk, [:blended_video_chunk_id, :rendering_machine_id] => :environment do |t, args|
		BlendedVideoChunkService.replace_chunk(args['blended_video_chunk_id'].to_i, args['rendering_machine_id'].to_i)
	end
end
