class IpAddressesController < ApplicationController
  before_action :set_ip_address, only: [:show, :edit, :update, :destroy, :return_ip_address]

	IP_ADDRESSES_DEFAULT_LIMIT = 25

  # GET /ip_addresses
  # GET /ip_addresses.json
  def index
		respond_to do |format|
      limit_present = params[:limit].present?
      params[:limit] = IP_ADDRESSES_DEFAULT_LIMIT unless params[:limit].present?

      if params[:filter].present?
        params[:filter][:order] = 'updated_at' unless params[:filter][:order].present?
        params[:filter][:order_type] = 'desc' unless params[:filter][:order_type].present?
      else
        params[:filter] = { order: 'updated_at', order_type: 'desc' }
      end

      order_by = params[:filter][:order]

      @ip_addresses = IpAddress.includes(:country)
      .by_id(params[:id])
      .by_address(params[:address])
      .by_port(params[:port])
      .by_country_id(params[:country_id])
      .by_rating(params[:rating])
      .by_additional_use(params[:additional_use])
      .page(params[:page]).per(params[:limit])
      .order('ip_addresses.' + order_by + ' ' + params[:filter][:order_type] + ' NULLS LAST')
      .references(:country)
			format.html {}
			format.json {@ip_addresses = IpAddress.all if !limit_present}
		end
  end

  # GET /ip_addresses/1
  # GET /ip_addresses/1.json
  def show
  end

  # GET /ip_addresses/new
  def new
    @ip_address = IpAddress.new
  end

  # GET /ip_addresses/1/edit
  def edit
  end

  # POST /ip_addresses
  # POST /ip_addresses.json
  def create
    @ip_address = IpAddress.new(ip_address_params)

    respond_to do |format|
      if @ip_address.save
        format.html { redirect_to ip_addresses_path, notice: 'Ip address was successfully created.' }
        format.json { render action: 'show', status: :created, location: @ip_address }
      else
        format.html { render action: 'new' }
        format.json { render json: @ip_address.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ip_addresses/1
  # PATCH/PUT /ip_addresses/1.json
  def update
    respond_to do |format|
      if @ip_address.update(ip_address_params)
        format.html { redirect_to ip_addresses_path, notice: 'Ip address was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @ip_address.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ip_addresses/1
  # DELETE /ip_addresses/1.json
  def destroy
    @ip_address.destroy
    respond_to do |format|
      format.html { redirect_to ip_addresses_path }
      format.json { head :no_content }
    end
  end

	def next_available_ip_address
    country = params[:country_id].present? ? Geobase::Country.where("id = ?", params[:country_id].to_i).first : nil
    ip_address = if country.present?
      IpAddress.next_available_ip_address(country, params[:proxy_type])
    else
      IpAddress.next_available_ip_address
    end
		response = ip_address.present? ? ip_address.to_json : ""
		render json: response, status: 200
	end

	def ip_address_for_account_creation
		ip_address = if Setting.get_value_by_name("EmailAccount::LAST_ORDER_ACCOUNT_TYPE").to_i == EmailAccount.account_type.find_value(:system).value
			country_code = Setting.get_value_by_name("EmailAccount::SYSTEM_TYPE_COUNTRY_CODE")
			if country_code.present?
				country = Geobase::Country.find_by_code(country_code)
				IpAddress.next_available_ip_address(country, "free_proxy")
			else
				""
			end
		else
			IpAddress.next_available_ip_address
		end
		response = ip_address.present? ? ip_address.to_json : ""
		render json: response, status: 200
	end

  def return_ip_address
    if params[:by_country] == true.to_s
      IpAddress.return_ip_address(@ip_address, true)
    else
      IpAddress.return_ip_address(@ip_address)
    end
    respond_to do |format|
      format.html { redirect_to ip_addresses_path, notice: 'Ip address was successfully return and reassigned to other ip addresses.' }
      format.json { head :no_content }
    end
  end

	def update_rating_statistics
		done = IpAddress.update_rating_statistics
		notice, alert = nil
		if done
			notice = "Rating for ip addresses was successfully updated"
		else
			alert = "Something went wrong while updating rating for ip addresses"
		end
		respond_to do |format|
			format.html { redirect_to :back, notice: notice, alert: alert }
			format.json { head :no_content }
		end
	end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ip_address
      @ip_address = IpAddress.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def ip_address_params
			params.require(:ip_address).permit!
    end
end
