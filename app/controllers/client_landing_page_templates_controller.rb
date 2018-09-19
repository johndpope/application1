class ClientLandingPageTemplatesController < ApplicationController
	before_action :set_client_landing_page_template, only: [:show, :edit, :update, :destroy]

	def index
		@client_landing_page_templates = ClientLandingPageTemplate.order(name: :asc)
	end

	def show
	end

	def new
		@client_landing_page_template = ClientLandingPageTemplate.new
	end

	def edit
	end

	def create
		@client_landing_page_template = ClientLandingPageTemplate.new(client_landing_page_template_params)

		respond_to do | format |
			if @client_landing_page_template.save
				format.html { redirect_to client_landing_page_templates_path, notice: 'Client landing page template was successfully created.' }
				format.json { render action: 'show', status: :created, location: @client_landing_page_template }
			else
				format.html { render action: 'new' }
				format.json { render json: @client_landing_page_template.errors, status: :unprocessable_entity }
			end
		end
	end

	def update
		respond_to do | format |
			if @client_landing_page_template.update(client_landing_page_template_params)
				format.html { redirect_to client_landing_page_templates_path, notice: 'Client landing page template was successfully updated.' }
				format.json { head :no_content }
			else
				format.html { render action: 'edit' }
				format.json { render json: @client_landing_page_template.errors, status: :unprocessable_entity }
			end
		end
	end

	def destroy
		@client_landing_page_template.destroy

		respond_to do | format |
			format.html { redirect_to client_landing_page_templates_path }
			format.json { head :no_content }
		end
	end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_client_landing_page_template
			@client_landing_page_template = ClientLandingPageTemplate.find(params[:id])
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def client_landing_page_template_params
			params.require(:client_landing_page_template).permit!
		end
end
