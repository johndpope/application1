class VideoScriptsController < ApplicationController
	VIDEO_SCRIPT_LIMIT = 20

	def index
		@video_scripts = VideoScript.order(created_at: :desc).page(params[:page]).per(VIDEO_SCRIPT_LIMIT)
	end	

	def body_json()
		render json: VideoScript.select([:body]).find(params[:id]).to_json
	end	

	def show
		@video_script = VideoScript.find(params[:id])
	end 
end
