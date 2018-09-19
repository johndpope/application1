class Public::BaseController < ActionController::Base
	include DataPage
	layout 'public_client'

	before_action :set_client

	private
		def set_client
			@client = Client.find_by_public_profile_uuid!(params[:id] || params[:client_id])
		end
end
