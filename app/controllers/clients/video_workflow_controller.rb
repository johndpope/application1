class Clients::VideoWorkflowController < ApplicationController
	include Clients::VideoWorkflowConcern
	LIMIT = 25

	before_action :set_client
	before_action :set_blended_video_chunk, only: %w(approve_blended_video_chunk show_notes update_notes regenerate_video_segment)

	def index
		q = params[:q] || {}
		@search = BlendedVideo.search(q.merge(client_id_eq: @client.id))
		query = @search.result

		@blended_videos = query.by_workflow_status_name(params[:workflow_status_name]).order(created_at: :desc).page(params[:page]).per(LIMIT)
		blended_video_ids = @blended_videos.pluck(:id)
		blended_video_chunk_ids = BlendedVideoChunk.where(blended_video_id: blended_video_ids).pluck(:id).to_a

		youtube_video_ids = YoutubeVideo.where(blended_video_id: blended_video_ids).pluck(:id)
		@rendering_progresses = BlendedVideo.rendering_progresses(@blended_videos.pluck(:id))
		@locations = (BlendedVideo.where(id: blended_video_ids).
			joins("LEFT OUTER JOIN geobase_countries ON blended_videos.location_id = geobase_countries.id AND blended_videos.location_type = 'Geobase::Country'").
			joins("LEFT OUTER JOIN geobase_regions ON blended_videos.location_id = geobase_regions.id AND blended_videos.location_type = 'Geobase::Region'").
			joins("LEFT OUTER JOIN geobase_regions AS geobase_regions2 ON geobase_regions.parent_id = geobase_regions2.id").
			joins("LEFT OUTER JOIN geobase_localities ON blended_videos.location_id = geobase_localities.id AND blended_videos.location_type = 'Geobase::Locality'").
			joins("LEFT OUTER JOIN geobase_regions AS geobase_regions3 ON geobase_localities.primary_region_id = geobase_regions3.id").
			select(['blended_videos.id',
				'geobase_countries.id as gc_id', 'geobase_countries.name as gc_name', 'NULL as gc_parent_name', "'Country' AS gc_loc_type",
				'geobase_regions.id as gr_id', 'geobase_regions.name as gr_name', "split_part(geobase_regions2.code,'<sep/>',1) as gr_parent_name", "'Region' AS gr_loc_type",
				'geobase_localities.id as gl_id', 'geobase_localities.name as gl_name', 'geobase_regions3.code AS gl_parent_name', "'Locality' AS gl_loc_type"]).
			map do |bv|
				loc = {}
				%w(c r l).each do |t|
					unless bv.send("g#{t}_id").nil?
						%w(id name parent_name loc_type).each do |f|
							loc[f.to_sym] = bv.send("g#{t}_#{f}")
						end
					end
				end
				{bv.id => {id: loc[:id], name: [loc[:name], loc[:parent_name]].join(', '), type: loc[:loc_type]}}
			end).inject(:merge)

			@delayed_jobs = {segment_generation: {}, blending: {}, youtube_video_content_creation: {}, youtube_video_thumbnail_creation: {}}

			@delayed_jobs[:blending][:total_count] = dj_segment_blending_scope(@client.id).count
			@delayed_jobs[:blending][:failed_count] = dj_segment_blending_scope(@client.id, only_failed_jobs: true).count
			@delayed_jobs[:blending][:items] = (dj_segment_blending_scope(@client.id, blended_video_ids: blended_video_ids).order("delayed_jobs.created_at").map do |dj|
				{dj.blended_video_id => {id: dj.id, last_error: dj.last_error, created_at: dj.created_at, attempts: dj.attempts}}
			end).inject(:merge) || {}



			@delayed_jobs[:youtube_video_content_creation][:total_count] = dj_youtube_video_content_creation_scope(@client.id).count
			@delayed_jobs[:youtube_video_content_creation][:failed_count] = dj_youtube_video_content_creation_scope(@client.id, only_failed_jobs: true).count
			@delayed_jobs[:youtube_video_content_creation][:items] = (dj_youtube_video_content_creation_scope(@client.id, blended_video_ids: blended_video_ids).order("delayed_jobs.created_at").map do |dj|
				{dj.blended_video_id => {id: dj.id, last_error: dj.last_error, created_at: dj.created_at, attempts: dj.attempts}}
			end).inject(:merge) || {}

			@delayed_jobs[:youtube_video_thumbnail_creation][:total_count] = dj_youtube_video_thumbnail_creation_scope(@client.id).count
			@delayed_jobs[:youtube_video_thumbnail_creation][:failed_count] = dj_youtube_video_thumbnail_creation_scope(@client.id, only_failed_jobs: true).count
			@delayed_jobs[:youtube_video_thumbnail_creation][:items] = (dj_youtube_video_thumbnail_creation_scope(@client.id, youtube_video_ids: youtube_video_ids).order("delayed_jobs.created_at").map do |dj|
				{dj.blended_video_id => {id: dj.id, last_error: dj.last_error, created_at: dj.created_at, attempts: dj.attempts}}
			end).inject(:merge) || {}

			@delayed_jobs[:segment_generation][:total_count] = dj_segment_generation_scope(@client.id).count
			@delayed_jobs[:segment_generation][:failed_count] = dj_segment_generation_scope(@client.id, only_failed_jobs: true).count
			@delayed_jobs[:segment_generation][:items] = (dj_segment_generation_scope(@client.id, blended_video_chunk_ids: blended_video_chunk_ids).order("delayed_jobs.created_at").map do |dj|
				{dj.blended_video_chunk_id => {id: dj.id, last_error: dj.last_error, created_at: dj.created_at, attempts: dj.attempts}}
			end).inject(:merge) || {}

			@has_failed_delayed_jobs = @delayed_jobs.map{|k,v|v[:failed_count].to_i}.sum > 0

		@blending_patterns = BlendedVideoChunk.
			select('chunk_type, blended_video_id').
			where(blended_video_id: @blended_videos.pluck(:id)).
			order(order_nr: :asc).
			group_by(&:blended_video_id).
			map{|k,v|{k => v.collect{|bvc|bvc.chunk_type}}}.inject(:merge)

		#General Workflow Progress
		total_count = BlendedVideo.joins(:client).where("clients.id" => @client.id).count
		yv_scope = YoutubeVideo.joins(:client).where("clients.id" => @client.id)
		posting_on_youtube = yv_scope.where(ready: true, linked: true).where.not(youtube_video_id: nil).count
		bv_scope = BlendedVideo.joins(:client).where("clients.id" => @client.id)
		@client_workflow_progress = {
			segment_generation: (bv_scope.segments_generated.count.to_f/total_count.to_f)*100,
			segment_transmition: (bv_scope.segments_transmitted.count.to_f/total_count.to_f)*100,
			segment_rendering: (bv_scope.rendered.count.to_f/total_count.to_f)*100,
			blending: (bv_scope.blended.count.to_f/total_count.to_f)*100,
			content_creation: (yv_scope.count.to_f/total_count.to_f)*100,
			posting_on_youtube: (posting_on_youtube.to_f/total_count.to_f)*100
		}
	end

	def approve_blended_video_chunk
		if %w(true false).include?(params[:status]) || params[:status].blank?
			ActiveRecord::Base.transaction{
				@blended_video_chunk.accepted = params[:status].to_s
				@blended_video_chunk.save!
			}
		end
	end

	def approve_blended_video
		@blended_video = BlendedVideo.find(params[:id])
		if %w(true false).include?(params[:status]) || params[:status].blank?
			ActiveRecord::Base.transaction{
				BlendedVideoChunk.where(blended_video_id: @blended_video.id).update_all(accepted: params[:status].nil? ? nil : params[:status])
			}
		end
	end

	def show_notes
	end

	def update_notes
		unless @blended_video_chunk.dynamic_aae_project.blank?
			@blended_video_chunk.dynamic_aae_project.notes = params[:blended_video_chunk_notes]
			@blended_video_chunk.dynamic_aae_project.save!
		end
	end

	def video_chunks_block
		@blended_video = BlendedVideo.find(params[:id])
		@has_youtube_video_jobs = Delayed::Job.
			where("handler like '%Youtube::CreateYoutubeVideoJob%'").
			where("handler like E'%blended_video_id: ?\n%'", @blended_video.id).exists? == "1"

		@delayed_jobs = {}
		blended_video_chunk_ids = BlendedVideoChunk.where(blended_video_id: @blended_video.id).pluck(:id).to_a
		@delayed_jobs[:segment_generation] = (dj_segment_generation_scope(@client.id, blended_video_chunk_ids: blended_video_chunk_ids).order("delayed_jobs.created_at").map do |dj|
			{dj.blended_video_chunk_id => dj}
		end).inject(:merge) || {}
	end

	def regenerate_video_segment
		rendering_machine_id = RenderingMachine.
			where(is_active: true).
			where("is_test IS NOT TRUE").
			where(is_accessible: true).
			order('RANDOM()').first.id
		BlendedVideoChunkService.replace_chunk @blended_video_chunk.id, rendering_machine_id
	end

	def delayed_jobs
		dj_limit = 50
		@blended_video = BlendedVideo.find(params[:video_set_id])
		if %w(segment_generation segment_transmission blending content_creation).include? params[:workflow_stage]
			@failed_delayed_jobs = if %w(segment_generation segment_transmission).include? params[:workflow_stage]
				blended_video_chunk_ids = params[:video_segment_id].blank? ? BlendedVideoChunk.
																																			joins(:blended_video).
																																			where("blended_videos.id" => @blended_video.id).
																																			pluck("blended_video_chunks.id") : [params[:video_segment_id]]
				dj_segment_generation_scope(@client.id, blended_video_chunk_ids: blended_video_chunk_ids)
			elsif params[:workflow_stage] == 'blending'
				dj_segment_blending_scope(@client.id, blended_video_ids: [@blended_video.id]).limit(dj_limit)
			elsif params[:workflow_stage] == 'content_creation'
				dj_youtube_video_content_creation_scope(@client.id, blended_video_ids: [@blended_video.id]).limit(dj_limit)
			end
		end
	end

	def video_segment_failed_delayed_jobs

	end

	private
		def set_blended_video_chunk
			@blended_video_chunk = BlendedVideoChunk.find(params[:id])
		end

		def set_client
			@client = Client.find(params[:client_id])
		end
end
