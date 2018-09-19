class VkontakteController < ApplicationController
	def oauth
		session[:state] = Digest::MD5.hexdigest(rand.to_s)
		redirect_to VkontakteApi.authorization_url(type: :client, scope: %w(offline), state: session[:state])
	end

	def oauth_callback
		params[:code]
	end
end
