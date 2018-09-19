class PhoneCallsController < ApplicationController
  before_action :set_phone_call, only: [:show, :edit, :update, :destroy]
  PHONE_CALL_DEFAULT_LIMIT = 25

  # GET /phone_calls
  # GET /phone_calls.json
  def index
    if params[:id].present?
      phone_call = PhoneCall.find_by_id(params[:id])
      if phone_call.present? && (!phone_call.admin_user.present? || params[:unlock] == 'true')
        phone_call.admin_user = current_admin_user
        phone_call.save
      end
    end
    params[:limit] = PHONE_CALL_DEFAULT_LIMIT unless params[:limit].present?
    @phone_calls = PhoneCall.all
    .by_id(params[:id])
    .by_call_file_url(params[:call_file_url])
    .order(created_at: :desc)
    .page(params[:page]).per(params[:limit])
  end

  # GET /phone_calls/1
  # GET /phone_calls/1.json
  def show
    response = { sms: @phone_call.sms_code }
    render json: response
  end

  # POST /phone_calls
  # POST /phone_calls.json
  def create
    phone_call_params = params
    phone_call_params.delete(:phone)
    phone_call_params[:phone_id] = if params[:phone].present?
      Phone.find_by_value(params[:phone]).try(:id)
    else
      nil
    end
    @phone_call = PhoneCall.new(phone_call_params)
    response = if @phone_call.save
      { id: @phone_call.id, status: 200 }
    else
      { status: 500 }
    end
    render json: response, status: response[:status]
  end

  # PATCH/PUT /phone_calls/1
  # PATCH/PUT /phone_calls/1.json
  def update
    phone_call_params[:admin_user_id] = current_admin_user.id
    ap phone_call_params
    respond_to do |format|
      if @phone_call.update(phone_call_params)
        format.html { redirect_to @phone_call, notice: 'Phone call was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @phone_call.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /phone_calls/1
  # DELETE /phone_calls/1.json
  def destroy
    @phone_call.destroy
    respond_to do |format|
      format.html { redirect_to phone_calls_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_phone_call
      @phone_call = PhoneCall.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def phone_call_params
      params.require(:phone_call).permit!
    end
end
