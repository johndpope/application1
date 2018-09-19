class ClientLandingPagesController < ApplicationController
	include ClientLandingPagesHelper
	before_action :set_client_landing_page, only: [:show, :edit, :update, :destroy, :generate_landing_page, :park_and_host, :upload_index_file]
	skip_before_filter :authenticate_admin_user!, :only => [:generate_landing_page]
  CLIENT_LANDING_PAGE_DEFAULT_SHARE_ICON_PATH = "images/share_icon.png"

	def index
    if params[:filter].present?
      unless params[:filter][:order].present?
        params[:filter][:order] = "updated_at"
      end
      unless params[:filter][:order_type].present?
        params[:filter][:order_type] = "asc"
      end
    else
      params[:filter] = {order: "updated_at", order_type: "asc" }
    end
		@client_landing_pages = if params[:client_id].present?
			@client = Client.find(params[:client_id].to_i)
			ClientLandingPage.where('client_id = ?', params[:client_id].to_i).order(params[:filter][:order] + " " + params[:filter][:order_type])
		else
			ClientLandingPage.all
		end
	end

	def show
	end

	def new
		@client_landing_page = if params[:client_id].present? || params[:client_landing_page][:client_id].present?
			client_id = params[:client_id] || params[:client_landing_page][:client_id]
			@client = Client.find(client_id.to_i)
			ClientLandingPage.new(client_id: client_id.to_i)
		else
			ClientLandingPage.new
		end
	end

	def edit
		@client = @client_landing_page.client
    if params[:auto_update].present?
      @client_landing_page.copy_backgrounds_urls
      @client_landing_page.save
    end
	end

	def create
		@client_landing_page = ClientLandingPage.new(client_landing_page_params)

		respond_to do | format |
			if @client_landing_page.save
				format.html { redirect_to client_client_landing_pages_path(client_id: @client_landing_page.client.id), notice: 'Client landing page was successfully created.' }
				format.json { render action: 'show', status: :created, location: @client_landing_page }
			else
				@client = Client.find(@client_landing_page.client_id)
				format.html {
          @client_landing_page = ClientLandingPage.new(client_landing_page_params)
          @client_landing_page.save(validate: false)
          redirect_to edit_client_client_landing_page_path(@client, id: @client_landing_page.id, auto_update: true)
        }
				format.json { render json: @client_landing_page.errors, status: :unprocessable_entity }
			end
		end
	end

	def update
		respond_to do | format |
      @client_landing_page.attributes = client_landing_page_params
      @client_landing_page.copy_backgrounds_urls
			if @client_landing_page.save
        url = if params[:submit_next].present?
          next_client_landing_page = ClientLandingPage.where(client_id: @client_landing_page.client.id).order(updated_at: :asc).first
          format.html { redirect_to edit_client_client_landing_page_path(client_id: @client_landing_page.client.id, id: next_client_landing_page.id), notice: 'Client landing page was successfully updated.' }
        else
          format.html { redirect_to client_client_landing_pages_path(client_id: @client_landing_page.client.id), notice: 'Client landing page was successfully updated.' }
        end
				format.json { head :no_content }
			else
				@client = Client.find(@client_landing_page.client_id)
				format.html { render action: 'edit' }
				format.json { render json: @client_landing_page.errors, status: :unprocessable_entity }
			end
		end
	end

	def destroy
		@client_landing_page.destroy

		respond_to do | format |
			format.html { redirect_to client_client_landing_pages_path(client_id: @client_landing_page.client.id) }
			format.json { head :no_content }
		end
	end

  def set
    @client_landing_page = ClientLandingPage.where("domain = ?", params[:domain]).order("subdomain DESC NULLS LAST").reverse.first
    if @client_landing_page.present?
      @client_landing_page.domain_token = params[:domain_token].strip if params[:domain_token].present?
      @client_landing_page.ignore_domain = "true"
    end
    response = if @client_landing_page && @client_landing_page.save
      { status: 200 }
    else
      { status: 500 }
    end
    render json: response, status: response[:status]
  end

  def get_domain_token
    response = if params[:domain].present?
      {domain_token: ClientLandingPage.where("domain = ? AND domain_token IS NOT NULL", params[:domain]).first.try(:domain_token).to_s }
    else
      {status: 500}
    end
    render json: response
  end

	def generate_landing_page
    @share_icon_url = CLIENT_LANDING_PAGE_DEFAULT_SHARE_ICON_PATH

		respond_to do | format |
			format.html { render "client_landing_page_templates/templates/#{@client_landing_page.client_landing_page_template.file_name}", layout: false }
		end
	end

	def park_and_host
		respond_to do | format |
			message = @client_landing_page.park_and_host
			format.html { redirect_to client_client_landing_pages_path(client_id: @client_landing_page.client.id), notice: message }
		end
	end

  def upload_index_file
    respond_to do | format |
      subdomain = @client_landing_page.subdomain
      domain = @client_landing_page.domain
      target_url = [subdomain, domain].reject(&:empty?).join(".")
      if target_url.present? && @client_landing_page.parked && @client_landing_page.hosted
        if @client_landing_page.save_piwik_id(target_url) || @client_landing_page.piwik_id.present?
          if @client_landing_page.save_piwik_code || @client_landing_page.piwik_code.present?
            @client_landing_page.upload_index_file
          end
        end
      end
      format.html { redirect_to client_client_landing_pages_path(client_id: @client_landing_page.client.id), notice: "Page was successfully re-uploaded" }
    end
  end

  def visitors_statistics
    client_landing_pages = ClientLandingPage.where("piwik_id IS NOT NULL").order(subdomain: :asc)
    respond_to do |format|
      format.html { render partial: 'client_landing_pages/statistics', layout: false, locals: {client_landing_pages: client_landing_pages } }
    end
  end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_client_landing_page
			@client_landing_page = ClientLandingPage.find(params[:id])
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def client_landing_page_params
			params[:client_landing_page][:body_sections] = params[:client_landing_page][:body_sections].to_s
			params.require(:client_landing_page).permit!
		end
end
