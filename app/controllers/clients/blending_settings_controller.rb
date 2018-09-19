class Clients::BlendingSettingsController < ApplicationController
	before_action :set_client

	def show
		@client.blending_settings ||= ClientBlendingSettings.new client_id: @client.id, use_instrumental_soundtrack_only: true, soundtrack_genre_blacklist: []
	end

	def update
		@client.blending_settings.update_attributes! blending_settings_params[:blending_settings_attributes]
		redirect_to client_blending_settings_path(@client)
	end

	private
		def set_client
			@client = Client.find(params[:client_id])
		end

		def blending_settings_params
			params.require(:client).
				permit(blending_settings_attributes:
					[:id, :client_id, :use_instrumental_soundtrack_only, :soundtrack_genre_blacklist])
		end
end
