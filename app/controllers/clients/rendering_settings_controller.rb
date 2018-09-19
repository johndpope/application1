class Clients::RenderingSettingsController < ApplicationController
	before_action :set_client

	def show
		@client.rendering_settings ||= ClientRenderingSettings.new client_id: @client.id
	end

	def update
		@client.rendering_settings.update_attributes! rendering_settings_params[:rendering_settings_attributes]
		redirect_to client_rendering_settings_path(@client)
	end

	private
		def set_client
			@client = Client.find(params[:client_id])
		end

		def rendering_settings_params
			params.require(:client).
				permit(rendering_settings_attributes: [:id, :rendering_priority,
					:auto_approve_rendered_video_chunks, :auto_blend_accepted_video_sets,
					:auto_create_youtube_video_content])
		end
end
