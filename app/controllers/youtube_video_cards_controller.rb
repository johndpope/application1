class YoutubeVideoCardsController < ApplicationController
	before_action :set_youtube_video_card, only: [:show, :edit, :update, :destroy, :set]

	def index
		@youtube_video_cards = YoutubeVideoCard.all
	end

	def show
	end

	def new
		@youtube_video_card = YoutubeVideoCard.new
		@youtube_video_card.youtube_video_id = params[:youtube_video_id] if params[:youtube_video_id].present?
	end

	def edit
	end

	def create
		@youtube_video_card = YoutubeVideoCard.new(youtube_video_card_params)

		respond_to do |format|
			if @youtube_video_card.save
				format.html { redirect_to edit_youtube_video_path(@youtube_video_card.youtube_video_id, anchor: 'cards-tab'), notice: 'Youtube video card was successfully created.' }
				format.json { render action: 'show', status: :created, location: @youtube_video_card }
			else
				format.html { render action: 'new' }
				format.json { render json: @youtube_video_card.errors, status: :unprocessable_entity }
			end
		end
	end

	def update
		respond_to do |format|
			if @youtube_video_card.update(youtube_video_card_params)
				format.html { redirect_to edit_youtube_video_path(@youtube_video_card.youtube_video_id, anchor: 'cards-tab'), notice: 'Youtube video card was successfully updated.' }
				format.json { head :no_content }
			else
				format.html { render action: 'edit' }
				format.json { render json: @youtube_video_card.errors, status: :unprocessable_entity }
			end
		end
	end

	def destroy
		@youtube_video_card.destroy

		respond_to do |format|
			format.html { redirect_to edit_youtube_video_path(@youtube_video_card.youtube_video_id, anchor: 'cards-tab') }
			format.json { head :no_content }
		end
	end

  def set
    @youtube_video_card.linked = params[:linked] if params[:linked].present?
    @youtube_video_card.card_title = params[:card_title] if params[:card_title].present?
    response = if @youtube_video_card.save
      @youtube_video_card.add_posting_time if params[:linked].present?
      { status: 200 }
    else
      { status: 500 }
    end
    render json: response, status: response[:status]
  end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_youtube_video_card
			@youtube_video_card = YoutubeVideoCard.find(params[:id])
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def youtube_video_card_params
			params.require(:youtube_video_card).permit!
		end
end
