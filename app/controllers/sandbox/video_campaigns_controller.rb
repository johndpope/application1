class Sandbox::VideoCampaignsController < Sandbox::BaseController
	before_action :set_sandbox_client, only: [:dropdown_options]

	def dropdown_options
		video_campaigns = video_campaigns(@sandbox_client.id, params[:locality_id])
		render partial: 'dropdown_options', locals: {video_campaigns: video_campaigns}
	end

	private
		def set_sandbox_client
			@sandbox_client = Sandbox::Client.find params[:client_uuid]
		end
end
