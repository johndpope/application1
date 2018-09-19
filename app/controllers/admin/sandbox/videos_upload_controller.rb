class Admin::Sandbox::VideosUploadController < Admin::BaseController
	def index
	end

	def upload
		ActiveRecord::Base.transaction do
			video_options = Templates::DynamicAaeProjects::ProjectGenerationService.get_project_options params[:sandbox_video][:file].first.original_filename
			video = Sandbox::Video.build_from_options(video_options)
			video.title = File.basename(params[:sandbox_video][:file].first.original_filename, '.mp4').gsub('_', ' ').gsub('-', ':')
			video.sandbox_video_set_id = params[:video_set_id]
			video_file = open(params[:sandbox_video][:file].first)

			thumb_file_path = File.join('/tmp', "#{SecureRandom.uuid}.jpg")
			Templates::AaeProject.dynamic_screenshot(video.templates_aae_project_id, params[:sandbox_video][:file].first.path).write(thumb_file_path)
			thumb_file = open(thumb_file_path)

			video.video = video_file
			video.thumb = thumb_file
			begin
				respond_to do |format|
					if video.save
						if !video_options[:dynamic_project].blank? && dynamic_project = Templates::DynamicAaeProject.find_by_id(video_options[:dynamic_project])
							video.templates_dynamic_aae_project_id = video_options[:dynamic_project]
							dynamic_project.rendered_video = video_file
							dynamic_project.rendered_video_thumb = thumb_file
						end
						format.json {render json: {files: [to_jq_upload(video)]}, status: :created}
					else
						format.json{render json: video.errors, status: :unprocessable_entity}
					end
				end
			rescue => exception
				throw exception
			ensure
				video_file.close
				thumb_file.close
				FileUtils.rm_rf thumb_file_path
			end
		end
	end

	private
		def to_jq_upload(video)
			{	"name" => video.video_file_name,
				"size" => video.video_file_size,
				"url" => video.thumb.url(:w60, timastamp: false),
				"delete_url" => "",
				"delete_type" => "" }
		end
end
