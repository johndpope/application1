class AssociatedWebsitesController < ApplicationController
  before_action :set_associated_website, only: [:show, :edit, :update, :destroy, :set]

	def index
		@associated_websites = AssociatedWebsite.all
	end

	def show
    respond_to do |format|
      format.html
      format.json{
        json_text = @associated_website.json
        render :json => json_text.to_json
      }
    end
	end

	def new
		@associated_website = AssociatedWebsite.new
		@associated_website.youtube_channel_id = params[:youtube_channel_id] if params[:youtube_channel_id].present?
	end

	def edit
	end

	def create
		@associated_website = AssociatedWebsite.new(associated_website_params)

		respond_to do |format|
			if @associated_website.save
				format.html { redirect_to edit_youtube_channel_path(@associated_website.youtube_channel_id, anchor: 'associated-websites-tab'), notice: 'Associated website was successfully created.' }
				format.json { render action: 'show', status: :created, location: @associated_website }
			else
				format.html { render action: 'new' }
				format.json { render json: @associated_website.errors, status: :unprocessable_entity }
			end
		end
	end

	def update
		respond_to do |format|
			if @associated_website.update(associated_website_params)
				format.html { redirect_to edit_youtube_channel_path(@associated_website.youtube_channel_id, anchor: 'associated-websites-tab'), notice: 'Associated website was successfully updated.' }
				format.json { head :no_content }
			else
				format.html { render action: 'edit' }
				format.json { render json: @associated_website.errors, status: :unprocessable_entity }
			end
		end
	end

	def destroy
		@associated_website.destroy

		respond_to do |format|
			format.html { redirect_to edit_youtube_channel_path(@associated_website.youtube_channel_id, anchor: 'associated-websites-tab') }
			format.json { head :no_content }
		end
	end

	def set
    @associated_website.linked = params[:linked] if params[:linked].present?
    @associated_website.ready = params[:ready] if params[:ready].present?
    @associated_website.association_method = AssociatedWebsite.association_method.find_value(params[:association_method].to_i) if params[:association_method].present?
    @associated_website.dns_record = params[:dns_record] if params[:dns_record].present?
		response = if @associated_website.save
      @associated_website.add_posting_time if params[:linked].present?
      youtube_channel = @associated_website.youtube_channel
      client_landing_page = @associated_website.client_landing_page
      if @associated_website.linked && @associated_website.ready && client_landing_page.present? && youtube_channel.present? && (youtube_channel.channel_links == "{\"links\":[]}" || youtube_channel.channel_links.nil?)
        channel_links = {}
        channel_links["links"] = [{"name"=>client_landing_page.title, "url"=>client_landing_page.page_url}]
        youtube_channel.channel_links = channel_links.to_s.gsub("=>", ":")
        youtube_channel.save
      end
			{ status: 200 }
		else
			{ status: 500 }
		end

		render json: response, status: response[:status]
	end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_associated_website
			@associated_website = AssociatedWebsite.find(params[:id])
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def associated_website_params
			params.require(:associated_website).permit!
		end
end
