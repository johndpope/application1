class Clients::DonorsController < ApplicationController
	before_action :set_client

	def create

	end

	def update

	end

	def destroy

	end

	private
		def set_client
			@client = Client.find(params[:client_id])
		end
end
