class CallToActionOverlaysController < ApplicationController
  before_action :set_call_to_action_overlay, only: [:show, :edit, :update, :destroy, :set]

  def index
    @call_to_action_overlays = CallToActionOverlay.all
  end

  def show
  end

  def new
    @call_to_action_overlay = CallToActionOverlay.new(enabled_on_mobile: true)
		@call_to_action_overlay.youtube_video_id = params[:youtube_video_id] if params[:youtube_video_id].present?
  end

  def edit
  end

  def create
    @call_to_action_overlay = CallToActionOverlay.new(call_to_action_overlay_params)

    respond_to do |format|
      if @call_to_action_overlay.save
        format.html { redirect_to edit_youtube_video_path(@call_to_action_overlay.youtube_video_id, :anchor => "call-to-action-overlay-tab"), notice: 'Call to action overlay was successfully created.' }
        format.json { render action: 'show', status: :created, location: @call_to_action_overlay }
      else
        format.html { render action: 'new' }
        format.json { render json: @call_to_action_overlay.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @call_to_action_overlay.update(call_to_action_overlay_params)
        format.html { redirect_to edit_youtube_video_path(@call_to_action_overlay.youtube_video_id, :anchor => "call-to-action-overlay-tab"), notice: 'Call to action overlay was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @call_to_action_overlay.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @call_to_action_overlay.destroy
    respond_to do |format|
      format.html { redirect_to edit_youtube_video_path(@call_to_action_overlay.youtube_video_id, :anchor => "call-to-action-overlay-tab") }
      format.json { head :no_content }
    end
  end

  def set
    @call_to_action_overlay.linked = params[:linked] if params[:linked].present?
    response = if @call_to_action_overlay.save
      @call_to_action_overlay.add_posting_time if params[:linked].present?
      { status: 200 }
    else
      { status: 500 }
    end
    render json: response, status: response[:status]
	end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_call_to_action_overlay
			@call_to_action_overlay = CallToActionOverlay.find(params[:id])
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def call_to_action_overlay_params
		 params.require(:call_to_action_overlay).permit!
		end
end
