class Clients::ImageSelectionTagsController < ApplicationController
	before_action :set_client

	def edit_client_tags
	end

	def update_client_tags
		@client.update_attributes!(params.require(:client).permit(:client_name_tag_list, :tag_list))
		render :edit_client_tags
	end

	def edit_products_tags
	end

	def update_products_tags
		@client.update_attributes!(params.require(:client).permit(products_attributes: [:id, :artifacts_image_tag_list]))
		render :edit_products_tags
	end

	private
		def set_client
			@client = Client.find(params[:client_id])
		end
end
