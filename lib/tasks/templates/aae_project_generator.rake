namespace :templates do
	namespace :aae_project do
		namespace :generator do
			task :bulk_generation, [:options_str] => :environment do |t, args|
				options = {projects_count: 4, track_attributions: true}.merge eval(args.options_str.gsub(';', ','))
				client = Client.find(options[:client_id])
				product = Product.find(options[:product_id])

				options[:source_video_ids].to_a.each do |source_video_id|
					source_video = SourceVideo.find(source_video_id)
					options[:locations].to_a.each do |location|
						options[:project_types].to_a.each do |project_type|
							aae_projects = Templates::AaeProject.with_project_type(project_type).
								where("is_special IS NOT TRUE").
								where(is_approved: true).
								order('RANDOM()').
								limit(options[:projects_count])
							aae_projects.each do |aae_project|
								puts ""
								puts "project_type: #{project_type}, project_id: #{aae_project.id}, source video: #{source_video.custom_title}, location: #{location}"
								Templates::AaeProjectGenerator.new(client: client,
									product: product,
									aae_project: aae_project,
									location: location,
									source_video: source_video,
									track_attributions: options[:track_attributions],
									target: options[:target]).generate
							end
						end
					end
				end
			end
		end
	end
end
