class Public::Credits::Youtube::VideosController < Public::Credits::BaseController
	YOUTUBE_VIDEO_LIMIT = 24
	YOUTUBE_VIDEO_IMAGE_LIMIT = 8
	def index
		@youtube_videos = YoutubeVideo.
			where("blended_video_id IS NOT NULL").
			page(params[:page]).
			per(YOUTUBE_VIDEO_LIMIT)
	end

	def show
		@youtube_video = if params.key? :blended_video_id
												BlendedVideo.joins(:youtube_video).find(params[:blended_video_id]).youtube_video
										 else
												YoutubeVideo.find(params[:id])
										 end
		dynamic_aae_project_ids = @youtube_video.try(:blended_video).try(:dynamic_aae_projects).try(:pluck, :id)
		@credited_images = Attribution.joins("INNER JOIN templates_dynamic_aae_project_images ON attributions.resource_type = 'Templates::DynamicAaeProjectImage' AND attributions.resource_id = templates_dynamic_aae_project_images.id").
			where("resource_type=? AND component_type = ?", "Templates::DynamicAaeProjectImage", "Artifacts::Image").
			where("templates_dynamic_aae_project_images.dynamic_aae_project_id" => dynamic_aae_project_ids).
			order(created_at: :asc).
			page(params[:page]).
			per(YOUTUBE_VIDEO_IMAGE_LIMIT)
	end
end
