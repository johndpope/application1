class VideoWorkflowController < ApplicationController
	LIMIT = 25

	before_action :set_blended_video_chunk, only: %w(approve_blended_video_chunk show_notes update_notes)

	def index
		@search = BlendedVideo.search(params[:q])
		query = @search.result

		#TODO Refactor using ransack custom filters
		unless params[:q].blank?
			query = if params[:q].key? 'completed_eq'
				query.completed
			elsif params[:q].key? 'completed_unreviewed_eq'
				query.completed_unreviewed
			elsif params[:q].key? 'rejected_eq'
				query.rejected
			elsif params[:q].key? 'accepted_eq'
				query.accepted
			else
				query
			end
		end

		@blended_videos = query.order(created_at: :desc).page(params[:page]).per(LIMIT)
		@rendering_progresses = BlendedVideo.rendering_progresses(@blended_videos.pluck(:id))
	end

	def approve_blended_video_chunk
		if %w(true false).include?(params[:status]) || params[:status].blank?
			@blended_video_chunk.accepted = params[:status].to_s
			@blended_video_chunk.save!
		end
	end

	def approve_blended_video
		@blended_video = BlendedVideo.find(params[:id])
		if %w(true false).include?(params[:status]) || params[:status].blank?
			BlendedVideoChunk.where(blended_video_id: @blended_video.id).update_all(accepted: params[:status].nil? ? nil : params[:status])
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
	end

	private
		def set_blended_video_chunk
			@blended_video_chunk = BlendedVideoChunk.find(params[:id])
		end
end
