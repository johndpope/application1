class Clients::RecipientsController < ApplicationController
	before_action :set_client

	def index
		@recipients = @client.recipients.page(params[:page]).per(50)
	end

	private
		def set_client
			@client = Client.find(params[:client_id])
		end
end
