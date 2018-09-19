class EmailAccountsSetupsController < ApplicationController
  before_action :set_email_accounts_setup, only: [:show, :edit, :update, :destroy]

  # GET /email_accounts_setups
  # GET /email_accounts_setups.json
  def index
    @email_accounts_setups = if params[:client_id].present?
      @client = Client.find(params[:client_id].to_i)
      EmailAccountsSetup.where("client_id = ?", params[:client_id].to_i)
    else
      EmailAccountsSetup.all
    end
  end

  # GET /email_accounts_setups/1
  # GET /email_accounts_setups/1.json
  def show
  end

  # GET /email_accounts_setups/new
  def new
    @email_accounts_setup = if params[:client_id].present? || params[:email_accounts_setup][:client_id]
      client_id = params[:client_id] || params[:email_accounts_setup][:client_id]
      @client = Client.find(client_id.to_i)
      contract_id =  if params[:contract_id].present?
        params[:contract_id].to_i
      else
        nil
      end
      EmailAccountsSetup.new(client_id: client_id.to_i, channels_per_account: 1, package: 1, contract_id: contract_id, gplus_business_pages_per_account: 1)
    else
      EmailAccountsSetup.new
    end
     @email_accounts_setup.country = Geobase::Country.where("LOWER(name) = ?", "united states of america").first if @email_accounts_setup.country.nil?
     @states = Geobase::Region.where(country_id: @email_accounts_setup.country_id, level: 1).order(:name)
     @email_accounts_setup
		 ap @email_accounts_setup
  end

  # GET /email_accounts_setups/1/edit
  def edit
    @client = @email_accounts_setup.client
    if [4,5].include?(@email_accounts_setup.package.value)
      cities = Geobase::Locality.where("id in (#{@email_accounts_setup.cities.to_s.gsub(/(\[|\])|"/, '')})").order(:name) if @email_accounts_setup.cities.present?
      counties = Geobase::Region.where("id in (#{@email_accounts_setup.counties.to_s.gsub(/(\[|\]|")/, '')})").order(:name) if @email_accounts_setup.counties.present?
      @cities_json = cities.map { |e| {id: e.id, text: "#{e.name}, #{e.try(:primary_region).try(:code).try(:split, '<sep/>').try(:first).to_s.gsub('US-', '')}"} }.to_json if cities.present?
      @counties_json = counties.map { |e| {id: e.id, text: "#{e.name}, #{e.try(:parent).try(:code).try(:split, '<sep/>').try(:first).to_s.gsub('US-', '')}"} }.to_json if counties.present?
    end
  end

  # POST /email_accounts_setups
  # POST /email_accounts_setups.json
  def create
    @email_accounts_setup = EmailAccountsSetup.new(email_accounts_setup_params)

    respond_to do |format|
      if @email_accounts_setup.save
        format.html { redirect_to new_client_youtube_setup_path(client_id: @email_accounts_setup.client.id, email_accounts_setup_id: @email_accounts_setup.id), notice: 'Email accounts setup was successfully created.' }
        format.json { render action: 'show', status: :created, location: @email_accounts_setup }
      else
        @client = Client.find(@email_accounts_setup.client_id)
        @email_accounts_setup.country = Geobase::Country.where("LOWER(name) = ?", "united states of america").first if @email_accounts_setup.country.nil?
        @states = Geobase::Region.where(country_id: @email_accounts_setup.country_id, level: 1).order(:name)
        format.html { render action: 'new' }
        format.json { render json: @email_accounts_setup.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /email_accounts_setups/1
  # PATCH/PUT /email_accounts_setups/1.json
  def update
    respond_to do |format|
      if @email_accounts_setup.update(email_accounts_setup_params)
        format.html { redirect_to client_email_accounts_setups_path(client_id: @email_accounts_setup.client_id), notice: 'Email accounts setup was successfully updated.' }
        format.json { head :no_content }
      else
        @client = @email_accounts_setup.client
        format.html { render action: 'edit' }
        format.json { render json: @email_accounts_setup.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /email_accounts_setups/1
  # DELETE /email_accounts_setups/1.json
  def destroy
    @email_accounts_setup.destroy
    respond_to do |format|
      format.html { redirect_to client_email_accounts_setups_path(client_id: @email_accounts_setup.client_id) }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_email_accounts_setup
      @email_accounts_setup = EmailAccountsSetup.find(params[:id])
      @states = Geobase::Region.where(country_id: @email_accounts_setup.country_id, level: 1).order(:name)
      if @email_accounts_setup.package.nil?
        @email_accounts_setup.country = Geobase::Country.where("LOWER(name) = ?", "united states of america").first if @email_accounts_setup.country.nil?
        @email_accounts_setup.package = 1
        @email_accounts_setup
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def email_accounts_setup_params
      params.require(:email_accounts_setup).permit!
    end
end
