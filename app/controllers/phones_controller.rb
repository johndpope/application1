class PhonesController < ApplicationController
  before_action :set_phone, only: [:show, :edit, :update, :destroy, :cancel_voipms_did, :park_did]
  PHONE_DEFAULT_LIMIT = 25

  # GET /phones
  # GET /phones.json
  def index
    params[:limit] = PHONE_DEFAULT_LIMIT unless params[:limit].present?
		if params[:filter].present?
			params[:filter][:order] = 'ordered_at' unless params[:filter][:order].present?
			params[:filter][:order_type] = 'desc' unless params[:filter][:order_type].present?
		else
			params[:filter] = { order: 'ordered_at', order_type: 'desc' }
		end
    order_by = if params[:filter][:order] == 'last_used_at'
      'max_phone_usage_created_at'
    else
      'phones.' +  params[:filter][:order]
    end

    column_names = Phone.column_names
    column_names_string = "phones." + column_names.join(",phones.")

    @phones = Phone.unscoped.distinct.select("#{column_names_string} #{', (SELECT MAX(phone_usages.created_at) FROM phone_usages WHERE phone_usages.phone_id = phones.id) as max_phone_usage_created_at' if params[:filter][:order] == 'last_used_at'}").joins("LEFT OUTER JOIN geobase_countries ON geobase_countries.id = phones.country_id LEFT OUTER JOIN phone_providers ON phone_providers.id = phones.phone_provider_id LEFT OUTER JOIN phone_usages ON phone_usages.phone_id = phones.id")
			.by_id(params[:id])
			.by_phone_provider_id(params[:phone_provider_id])
			.by_value(params[:value])
			.by_status(params[:status])
			.by_country_id(params[:country_id])
			.by_region_id(params[:region_id])
      .by_usable(params[:usable])
      .by_facebook_usable(params[:facebook_usable])
	    .page(params[:page]).per(params[:limit])
	    .order(order_by + ' ' + params[:filter][:order_type] + ' NULLS LAST')
  end

  # GET /phones/1
  # GET /phones/1.json
  def show
  end

  # GET /phones/new
  def new
    @phone = Phone.new
  end

  # GET /phones/1/edit
  def edit
  end

  # POST /phones
  # POST /phones.json
  def create
    @phone = Phone.new(phone_params)

    respond_to do |format|
      if @phone.save
        format.html { redirect_to phones_path, notice: 'Phone was successfully created.' }
        format.json { render action: 'show', status: :created, location: @phone }
      else
        format.html { render action: 'new' }
        format.json { render json: @phone.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /phones/1
  # PATCH/PUT /phones/1.json
  def update
    respond_to do |format|
      if @phone.update(phone_params)
        format.html { redirect_to phones_path, notice: 'Phone was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @phone.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /phones/1
  # DELETE /phones/1.json
  def destroy
    @phone.destroy
    respond_to do |format|
      format.html { redirect_to phones_url }
      format.json { head :no_content }
    end
  end

	def park_did
		@phone.park_did
		respond_to do |format|
			format.html { redirect_to :back }
			format.json { head :no_content }
		end
	end

	def cancel_voipms_did
		phone_service_account = PhoneServiceAccount.includes(:phone_service).where("phone_services.name = ?", "VOIP-MS").first
		VoipmsService.cancel_did(phone_service_account, @phone) if phone_service_account.present?
		respond_to do |format|
			format.html { redirect_to phones_url }
			format.json { head :no_content }
		end
	end


	def next_available_did
		phone = VoipmsService.next_available_did
		response = phone.present? ? phone.to_json : ""
		render json: response, status: 200
	end

	def phone_number_for_account_creation
		phone = if Setting.get_value_by_name("EmailAccount::LAST_ORDER_ACCOUNT_TYPE").to_i == EmailAccount.account_type.find_value(:system).value
			""
		else
			VoipmsService.next_available_did
		end
		response = phone.present? ? phone.to_json : ""
		render json: response, status: 200
	end

  def unusable
    target = params[:target].present? ? "#{params[:target]}_" : ""
    phone = Phone.find_by_value(params[:number].strip)
    response = if phone.present?
      phone["#{target}usable"] = false
      phone["#{target}unusable_at"] = Time.now
      phone.save
      #send pushbullet notification to return back DID if no accounts assigned
      if phone.email_accounts_assigned_size == 0
        Utils.pushbullet_broadcast("DID #{phone.value} was marked as unusable!", "DID #{phone.value} was marked as unusable at #{Time.now.utc} and have no accounts assigned, please recheck it and return back.")
      end
      {status: 200}
    else
      {status: 404}
    end
    render json: response, status: response[:status]
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_phone
      @phone = Phone.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def phone_params
      %w(ordered_at expires_at).each do |field|
        params[:phone][field] = DateTime.strptime(params[:phone][field], '%m/%d/%Y') if params[:phone][field].present?
      end
      params.require(:phone).permit!
    end
end
