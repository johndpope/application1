class RecoveryAttemptResponsesController < ApplicationController
  before_action :set_recovery_attempt_response, only: [:show, :edit, :update, :destroy]
  RECOVERY_ATTEMPT_RESPONSE_DEFAULT_LIMIT = 25

  # GET /recovery_attempt_responses
  # GET /recovery_attempt_responses.json
  def index
    if params[:filter].present?
      unless params[:filter][:order].present?
        params[:filter][:order] = "created_at"
      end
      unless params[:filter][:order_type].present?
        params[:filter][:order_type] = "asc"
      end
    else
      params[:filter] = {order: "updated_at", order_type: "desc" }
    end
    params[:response].strip! if params[:response].present?
    params[:limit] = RECOVERY_ATTEMPT_RESPONSE_DEFAULT_LIMIT unless params[:limit].present?
    @recovery_attempt_responses = RecoveryAttemptResponse.distinct
    .by_id(params[:id])
    .by_response(params[:response])
    .by_response_type(params[:response_type])
    .page(params[:page]).per(params[:limit])
    .order(params[:filter][:order] + " " + params[:filter][:order_type])
  end

  # GET /recovery_attempt_responses/1
  # GET /recovery_attempt_responses/1.json
  def show
  end

  # GET /recovery_attempt_responses/new
  def new
    @recovery_attempt_response = RecoveryAttemptResponse.new
    ap params
  end

  # GET /recovery_attempt_responses/1/edit
  def edit
  end

  # POST /recovery_attempt_responses
  # POST /recovery_attempt_responses.json
  def create
    @recovery_attempt_response = RecoveryAttemptResponse.new(recovery_attempt_response_params)

    respond_to do |format|
      if @recovery_attempt_response.save
        url = if params[:submit_next].present?
          format.html { redirect_to new_recovery_attempt_response_path(last_response_type: @recovery_attempt_response.response_type.try(:value)), notice: 'Recovery attempt response was successfully created.' }
        else
          format.html { redirect_to recovery_attempt_responses_path, notice: 'Recovery attempt response was successfully created.' }
        end
        format.json { render action: 'show', status: :created, location: @recovery_attempt_response }
      else
        format.html { render action: 'new' }
        format.json { render json: @recovery_attempt_response.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /recovery_attempt_responses/1
  # PATCH/PUT /recovery_attempt_responses/1.json
  def update
    respond_to do |format|
      if @recovery_attempt_response.update(recovery_attempt_response_params)
        format.html { redirect_to recovery_attempt_responses_path, notice: 'Recovery attempt response was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @recovery_attempt_response.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /recovery_attempt_responses/1
  # DELETE /recovery_attempt_responses/1.json
  def destroy
    @recovery_attempt_response.destroy
    respond_to do |format|
      format.html { redirect_to recovery_attempt_responses_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_recovery_attempt_response
      @recovery_attempt_response = RecoveryAttemptResponse.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def recovery_attempt_response_params
      params.require(:recovery_attempt_response).permit!
    end
end
