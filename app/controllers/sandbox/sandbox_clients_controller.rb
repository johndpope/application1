class Sandbox::SandboxClientsController < Sandbox::BaseController
	include Sandbox::SandboxClientsHelper

	before_action :set_sandbox_client, only: [:show, :video_campaign, :locality_campaign_videos, :video_campaigns, :content_blender_video_campaign_options]
	before_action :init_settings, only: [:show]
	before_action :init_locality_campaign_videos, only: [:locality_campaign_videos]
	before_action :build_campaign_video_map, only: [:locality_campaign_video_set]

	def show
	end

	def content_blender_video_campaign_options
		render partial: 'sandbox/sandbox_clients/show/video_campaign_options', locals: {locality_id: params[:locality_id]}
	end

	def locality_campaign_videos
	end

	def video_campaign
		render partial: 'sandbox/sandbox_clients/show/active_campaign_video_block', locals:{
			campaign_video_map: build_video_campaign_map(@sandbox_client, Geobase::Locality.find(params[:locality_id]), true)}
	end

	private
		def set_sandbox_client
			@sandbox_client = Sandbox::Client.joins(:client).find_by_uuid!(params[:uuid] || params[:client_uuid])
		end

		def init_settings
			locality_ids = Sandbox::VideoCampaignVideoStage.joins(:video_campaign).
				where("sandbox_video_campaigns.sandbox_client_id" => @sandbox_client.id).
				pluck(:locality_id).
				reject(&:blank?).
				uniq
			@client_campaign_localities = Geobase::Locality.where(id: locality_ids).order(:name)
			@def_locality_id = @client_campaign_localities.first.try(:id)
			@def_locality_campaign_video_sets = video_campaigns(@sandbox_client.id, @def_locality_id)

			@client_video_campaign_maps = []
			@client_campaign_localities.each_with_index do | ccl, index |
				@client_video_campaign_maps << build_video_campaign_map(@sandbox_client, ccl, index == 0 ? true : false)
			end
		end

		def init_locality_campaign_videos
			@campaign_videos = CampaignVideo.where(campaign_video_set_id: params[:campaign_video_set_id], locality_id: params[:locality_id]).order(:month_nr)
		end

		def video_campaigns(sandbox_client_id, locality_id)
			Sandbox::VideoCampaign.
				joins(:sandbox_client).
				joins(:campaign_video_stages).
				where(sandbox_client_id: sandbox_client_id, 'sandbox_video_campaign_video_stages.locality_id' => locality_id).
				distinct.
				order(:created_at)
		end
end
