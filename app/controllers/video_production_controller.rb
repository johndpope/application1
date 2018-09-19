class VideoProductionController < ApplicationController
	SOURCE_VIDEO_LIMIT = 25
	VIDEO_SCRIPT_LIMIT = 25

	def source_videos
		@source_videos = SourceVideo.order(created_at: :desc).page(params[:page]).per(SOURCE_VIDEO_LIMIT)
	end

	def new_source_video

	end

	def edit_source_video
		
	end

	

	def create_sales_pitch

	end
	
end
