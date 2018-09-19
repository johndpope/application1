include ActionView::Helpers::TextHelper
class PhoneServiceAccountsController < ApplicationController
  skip_before_filter :authenticate_admin_user!, :only => [:sms_area_available_numbers]
  skip_before_filter :verify_authenticity_token, :only => [:sms_area_available_numbers]
  before_action :set_phone_service_account, only: [:show, :edit, :update, :destroy, :order_dids, :finish_order_dids, :voipms_regions]

  # GET /phone_service_accounts
  # GET /phone_service_accounts.json
  def index
    @phone_service_accounts = PhoneServiceAccount.all.order(id: :asc)
  end

  # GET /phone_service_accounts/1
  # GET /phone_service_accounts/1.json
  def show
  end

  # GET /phone_service_accounts/new
  def new
    @phone_service_account = PhoneServiceAccount.new
    @phone_service_account.build_api_account
  end

  # GET /phone_service_accounts/1/edit
  def edit
  end

  # POST /phone_service_accounts
  # POST /phone_service_accounts.json
  def create
    @phone_service_account = PhoneServiceAccount.new(phone_service_account_params)

    respond_to do |format|
      if @phone_service_account.save
        format.html { redirect_to phone_service_accounts_path, notice: 'Phone service account was successfully created.' }
        format.json { render action: 'show', status: :created, location: @phone_service_account }
      else
        format.html { render action: 'new' }
        format.json { render json: @phone_service_account.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /phone_service_accounts/1
  # PATCH/PUT /phone_service_accounts/1.json
  def update
    respond_to do |format|
      if @phone_service_account.update(phone_service_account_params)
        format.html { redirect_to phone_service_accounts_path, notice: 'Phone service account was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @phone_service_account.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /phone_service_accounts/1
  # DELETE /phone_service_accounts/1.json
  def destroy
    @phone_service_account.destroy
    respond_to do |format|
      format.html { redirect_to phone_service_accounts_url }
      format.json { head :no_content }
    end
  end

	def order_dids
	end

	def finish_order_dids
		regions_list = params[:regions_select]
		country_code = params[:country_select]
		dids_amount = params[:dids_number].to_i
		report = VoipmsService.orderVoipMsDids(@phone_service_account, country_code, regions_list, dids_amount)
		alert = if report[:error].present?
			alert = "Failed to order DIDs in "
			case country_code
			when "CA"
				report[:error].each {|key, value| alert += "#{VoipmsService::PROVINCES.select{|k, v| v == key}.keys.first}: #{value}, " }
			when "US"
				report[:error].each {|key, value| alert += "#{VoipmsService::STATES.select{|k, v| v == key}.keys.first}: #{value}, " }
			end
			alert.strip.chop
		else
			nil
		end

		respond_to do |format|
			format.html { redirect_to order_dids_phone_service_account_path(@phone_service_account), notice: "Successfully ordered #{pluralize(report[:success].to_i, 'DID')}", alert: alert }
			format.json { head :no_content }
		end
	end

	def voipms_regions
		country_code = params[:country_code]
		method = case country_code
		when "CA"
			"getProvinces"
		when "US"
			"getStates"
		else
			""
		end
		render json: VoipmsService.get_regions(@phone_service_account, country_code, method)
	end

  def sms_area_available_numbers
    response = PhoneServiceAccount.sms_area_available_numbers
    render json: response, status: response[:status]
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_phone_service_account
      @phone_service_account = PhoneServiceAccount.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def phone_service_account_params
      params.require(:phone_service_account).permit!
    end
end
