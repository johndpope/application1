class PhoneProvidersController < ApplicationController
  before_action :set_phone_provider, only: [:show, :edit, :update, :destroy]

  # GET /phone_providers
  # GET /phone_providers.json
  def index
    @phone_providers = PhoneProvider.all.order(name: :asc)
  end

  # GET /phone_providers/1
  # GET /phone_providers/1.json
  def show
  end

  # GET /phone_providers/new
  def new
    @phone_provider = PhoneProvider.new
  end

  # GET /phone_providers/1/edit
  def edit
  end

  # POST /phone_providers
  # POST /phone_providers.json
  def create
    @phone_provider = PhoneProvider.new(phone_provider_params)

    respond_to do |format|
      if @phone_provider.save
        format.html { redirect_to phone_providers_path, notice: 'Phone provider was successfully created.' }
        format.json { render action: 'show', status: :created, location: @phone_provider }
      else
        format.html { render action: 'new' }
        format.json { render json: @phone_provider.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /phone_providers/1
  # PATCH/PUT /phone_providers/1.json
  def update
    respond_to do |format|
      if @phone_provider.update(phone_provider_params)
        format.html { redirect_to phone_providers_path, notice: 'Phone provider was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @phone_provider.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /phone_providers/1
  # DELETE /phone_providers/1.json
  def destroy
    @phone_provider.destroy
    respond_to do |format|
      format.html { redirect_to phone_providers_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_phone_provider
      @phone_provider = PhoneProvider.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def phone_provider_params
      params[:phone_provider].each {|key, value| value.strip! }
      params.require(:phone_provider).permit!
    end
end
