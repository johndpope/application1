class PhoneServicesController < ApplicationController
  before_action :set_phone_service, only: [:show, :edit, :update, :destroy]

  # GET /phone_services
  # GET /phone_services.json
  def index
    @phone_services = PhoneService.all.order(name: :asc)
  end

  # GET /phone_services/1
  # GET /phone_services/1.json
  def show
  end

  # GET /phone_services/new
  def new
    @phone_service = PhoneService.new
  end

  # GET /phone_services/1/edit
  def edit
  end

  # POST /phone_services
  # POST /phone_services.json
  def create
    @phone_service = PhoneService.new(phone_service_params)

    respond_to do |format|
      if @phone_service.save
        format.html { redirect_to phone_services_path, notice: 'Phone service was successfully created.' }
        format.json { render action: 'show', status: :created, location: @phone_service }
      else
        format.html { render action: 'new' }
        format.json { render json: @phone_service.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /phone_services/1
  # PATCH/PUT /phone_services/1.json
  def update
    respond_to do |format|
      if @phone_service.update(phone_service_params)
        format.html { redirect_to phone_services_path, notice: 'Phone service was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @phone_service.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /phone_services/1
  # DELETE /phone_services/1.json
  def destroy
    @phone_service.destroy
    respond_to do |format|
      format.html { redirect_to phone_services_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_phone_service
      @phone_service = PhoneService.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def phone_service_params
      params[:phone_service].each {|key, value| value.strip! }
      params.require(:phone_service).permit!
    end
end
