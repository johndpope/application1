class OauthController < ApplicationController
	def soundcloud
		redirect_to "https://soundcloud.com/connect?scope=non-expiring&grand_type=authorization_code&response_type=code&display=popup&client_id=#{CONFIG['soundcloud']['client_id']}&redirect_uri=#{CONFIG['soundcloud']['callback_url']}"
	end

	def soundcloud_callback
		if params[:code]
				 response = %x(curl -X POST "https://api.soundcloud.com/oauth2/token" \\
								-F "client_id=#{CONFIG['soundcloud']['client_id']}" \\
								-F "client_secret=#{CONFIG['soundcloud']['client_secret']}" \\
								-F 'grant_type=authorization_code' \\
								-F "redirect_uri=#{CONFIG['soundcloud']['callback_url']}" \\
								-F "code=#{params[:code]}")

				resp = JSON::load(response)
				session[:soundcloud_refresh_token] = resp["access_token"]
				flash = {success: "Successfully refreshed!"}
		else
				flash = {error: "#{params[:error]} #{params[:error_description]}"}
		end

		redirect_to url_for(controller: :oauth, action: :soundcloud_refresh_token), flash: flash
	end

	def soundcloud_refresh_token
	end
end
