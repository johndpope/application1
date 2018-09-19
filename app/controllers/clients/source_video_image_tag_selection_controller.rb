class Clients::SourceVideoImageTagSelectionController < ApplicationController
	include GenericCrudElementsHelper
	before_action :set_client
	before_action :set_source_video, only: %w(edit_source_video_tags update)

	def source_videos_tags
		@search = SourceVideo.search(params[:q])
		@source_videos = @search.result.
			joins(:client).
			where("clients.id" => @client.id).
			page(params[:page]).per(25)
	end

	def edit_source_video_tags
		generic_form_dialog @source_video
	end

	def update
		@source_video.assign_attributes(params.require(:source_video).permit(:artifacts_image_tag_list))
		unless @source_video.save(validate: false)
			generic_form_dialog @source_video
		end
	end

	private
		def set_client
			@client = Client.find(params[:client_id])
		end

		def set_source_video
			@source_video = SourceVideo.find(params[:source_video_id] || params[:source_video][:id])			
			@view_folder = '/clients/source_video_image_tag_selection'
		end
end
