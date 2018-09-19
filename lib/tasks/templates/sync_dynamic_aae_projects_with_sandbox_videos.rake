namespace :templates do
	namespace :dynamic_aae_project do
		task sync_with_sandbox_videos: :environment do
			ActiveRecord::Base.transaction do
				Sandbox::Video.all.each do |sv|
					puts "processing video with title #{sv.title}"
					if options = Templates::DynamicAaeProjects::ProjectGenerationService.get_project_options(sv.title)
						if dynamic_project_id = options[:dynamic_project]
							if dynamic_project = Templates::DynamicAaeProject.find_by_id(options[:dynamic_project])
								sv.templates_dynamic_aae_project_id = options[:dynamic_project]
								sv.save!
								if File.exist? sv.video.path
									video_file = open(sv.video.path)
									dynamic_project.rendered_video = video_file
									video_file.close

									thumb_file_path = File.join('/tmp', "#{SecureRandom.uuid}.jpg")
									Templates::AaeProject.dynamic_screenshot(sv.templates_aae_project_id, sv.video.path).write(thumb_file_path)
									thumb_file = open(thumb_file_path)

									dynamic_project.save!
									FileUtils.rm_rf thumb_file_path
								end
							end
						end
					end
				end
			end
		end
	end
end
