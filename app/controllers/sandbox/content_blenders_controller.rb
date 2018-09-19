class Sandbox::ContentBlendersController < Sandbox::BaseController
  before_action :set_sandbox_client, only: [:preview]
	before_action :set_camaign_video_stages, only: [:preview]

	def preview
	end

	private
		def set_sandbox_client
			@sandbox_client = Sandbox::Client.find_by_uuid!(params[:client_uuid])
		end

		def set_camaign_video_stages
			@campaign_video_stages = @sandbox_client.
        campaign_video_stages.
        where(video_campaign_id: params[:content_blender_id],
          locality_id: params[:locality_id]).
        order(:month_nr)
		end
end
