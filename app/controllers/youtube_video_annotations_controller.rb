class YoutubeVideoAnnotationsController < ApplicationController
	before_action :set_youtube_video_annotation, only: [:show, :edit, :update, :destroy, :set]

	def index
		@youtube_video_annotations = YoutubeVideoAnnotation.all
	end

	def show
	end

	def new
		@youtube_video_annotation = YoutubeVideoAnnotation.new(font_size: YoutubeVideoAnnotation::FONT_SIZES.second)
		@youtube_video_annotation.youtube_video_id = params[:youtube_video_id] if params[:youtube_video_id].present?
	end

	def edit
	end

	def create
		@youtube_video_annotation = YoutubeVideoAnnotation.new(youtube_video_annotation_params)

		respond_to do |format|
			if @youtube_video_annotation.save
				format.html { redirect_to edit_youtube_video_path(@youtube_video_annotation.youtube_video_id, anchor: 'annotations-tab'), notice: 'Youtube video annotation was successfully created.' }
				format.json { render action: 'show', status: :created, location: @youtube_video_annotation }
			else
				format.html { render action: 'new' }
				format.json { render json: @youtube_video_annotation.errors, status: :unprocessable_entity }
			end
		end
	end

	def update
		respond_to do |format|
			if @youtube_video_annotation.update(youtube_video_annotation_params)
				format.html { redirect_to edit_youtube_video_path(@youtube_video_annotation.youtube_video_id, anchor: 'annotations-tab'), notice: 'Youtube video annotation was successfully updated.' }
				format.json { head :no_content }
			else
				format.html { render action: 'edit' }
				format.json { render json: @youtube_video_annotation.errors, status: :unprocessable_entity }
			end
		end
	end

	def destroy
		@youtube_video_annotation.destroy

		respond_to do |format|
			format.html { redirect_to edit_youtube_video_path(@youtube_video_annotation.youtube_video_id, anchor: 'annotations-tab') }
			format.json { head :no_content }
		end
	end

  def set
    @youtube_video_annotation.linked = params[:linked] if params[:linked].present?
    response = if @youtube_video_annotation.save
      @youtube_video_annotation.add_posting_time if params[:linked].present?
      { status: 200 }
    else
      { status: 500 }
    end
    render json: response, status: response[:status]
	end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_youtube_video_annotation
			@youtube_video_annotation = YoutubeVideoAnnotation.find(params[:id])
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def youtube_video_annotation_params
			params.require(:youtube_video_annotation).permit!
		end
end
