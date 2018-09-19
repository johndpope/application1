BLENDER_DIR = File.join('/tmp', 'broadcaster', 'aae_templates', 'blender')

namespace :templates do
	namespace :dynamic_aae_project do
		namespace :blender do
			task :blended_video_from_sandbox_video_set, [:options_str] => :environment do |t, args|
				options = eval(args.options_str.gsub(';', ','))
				tmp_folder_name = SecureRandom.uuid
				tmp_folder = FileUtils.mkdir_p File.join(BLENDER_DIR, tmp_folder_name)
				blending_patterns = [
					[:introduction, :summary_points, :bridge_to_subject, :subject, :call_to_action, :social_networks, :likes_and_views, :ending],
					[:collage, :bridge_to_subject, :subject, :summary_points, :call_to_action, :social_networks, :likes_and_views, :ending]
				]
				ActiveRecord::Base.transaction do
				    begin
					location = if options[:location][:type].titleize == "Locality"
							Geobase::Locality.locality_and_primary_region_name(options[:location][:name], options[:location][:state])
						    elsif options[:location][:type].titleize == "Region"
							Geobase::Region.county(options[:location][:name], options[:location][:state])
						    end
					blended_vid = BlendedVideo.create! source_id: options[:source_video_id], location_id: location.id, location_type: location.class.name

					blended_video_file_name_parts = []
					blended_video_file_name_parts << location.formatted_name(primary_region: true, primary_region_code: true).gsub(/[,']/, '').gsub(/\s/,'_').downcase
					blended_video_file_name_parts << ".mp4"
					blended_video_file_name = blended_video_file_name_parts.join('_')
					blended_video_file_path = File.join(tmp_folder,blended_video_file_name)

					puts "blending #{blended_video_file_name}"
					blending_pattern = blending_patterns[rand(0..(blending_patterns.size-1))]
					files_to_blend = []
					i = 1
					blending_pattern.each do |bp|
						query = Sandbox::Video.with_video_type(bp).where(sandbox_video_set_id: options[:video_set_id])
						query = Sandbox::Video.where("templates_dynamic_aae_project_id IS NOT NULL AND is_approved IS NOT FALSE").where(location_id: location.id, location_type: location.class.name) unless bp == :subject
						sandbox_video = query.with_video_type(bp).order('RANDOM()').first
						unless sandbox_video.blank?
							files_to_blend << sandbox_video.try(:video).path
							BlendedVideoChunk.create! blended_video_id: blended_vid.id, templates_dynamic_aae_project_id: sandbox_video.try(:dynamic_aae_project).try(:id), order_nr: i
							i += 1
						end
					end
					video_blender = VideoTools::VideoBlender.new(videos: files_to_blend)
					blended_video = video_blender.blend()
					blended_vid.file = blended_video
					blended_vid.save!
				    rescue Exception => e
					FileUtils.rm_rf tmp_folder_name
					raise e
				    end
				end
			end

			task :gabe_griess_generic_blended_videos, [:options_str] => :environment do |t, args|
				options = eval(args.options_str.gsub(';', ','))
				tmp_folder_name = SecureRandom.uuid
				tmp_folder = FileUtils.mkdir_p File.join(BLENDER_DIR, tmp_folder_name)
				blending_patterns = [
					[:introduction, :subject_video, :call_to_action, :social_networks, :likes_and_views, :ending],
					[:introduction, :call_to_action, :subject_video, :social_networks, :likes_and_views, :ending],
					[:introduction, :call_to_action, :subject_video, :ending, :social_networks, :likes_and_views]
				]
				client_id = 78
				subject_videos = SourceVideo.where(id: [287, 278])
				client_video_set_ids = Sandbox::VideoSet.joins(:client).where("clients.id = ?", client_id).pluck('sandbox_video_sets.id')
				youtube_channels = YoutubeChannel.joins(:google_account).
				    joins("INNER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id AND email_accounts.email_item_type = 'GoogleAccount'").
				    where("email_accounts.client_id = ?", client_id).
				    where("youtube_channels.id" => options[:youtube_channels]).
				    with_channel_type(:business)
				ActiveRecord::Base.transaction do
					begin
						if subject_videos.any?
							youtube_channels.each do |yc|
								subject_videos.each do |sv|
									blending_pattern = blending_patterns[rand(0..blending_patterns.size-1)]
									puts ""
									puts "source video id: #{sv.id}"
									puts "blending_pattern: #{blending_pattern.inspect}"
									puts "youtube_channel: #{yc.youtube_channel_name}"
									puts "location: #{yc.google_account.email_account.location.formatted_name}"
									chunks = []
									i = 1
									blended_video = BlendedVideo.create!(source_id: sv.id, location_id: yc.google_account.email_account.location.id, location_type: yc.google_account.email_account.location.class.name)
									blending_pattern.each_with_index do |bp, index|
										if bp == :subject_video
											chunks << sv.video.path
											BlendedVideoChunk.create! blended_video_id: blended_video.id, order_nr: i
											i += 1
										else
											video_chunk = Sandbox::Video.joins(:video_set).
												where("sandbox_video_sets.id" => client_video_set_ids).
												where("sandbox_videos.location_type = ? AND sandbox_videos.location_id = ?", yc.email_account.location.class.name, yc.email_account.location.id).
												where("sandbox_videos.is_approved IS NOT NULL AND sandbox_videos.is_active IS NOT NULL").
												where.not("sandbox_videos.templates_dynamic_aae_project_id" => nil).
												with_video_type(bp).
												order('RANDOM()').first

											if !video_chunk.blank? && !video_chunk.video.blank?
												BlendedVideoChunk.create! blended_video_id: blended_video.id, templates_dynamic_aae_project_id: video_chunk.templates_dynamic_aae_project_id, order_nr: i
												i += 1
												chunks << video_chunk.video.path
											end
										end
									end
									yv_title = []
									client_names = ['Mr. Griess', 'Gabe Griess', 'Gabe']
									video_subject_name = Templates::AaeProjectDynamicText.with_text_type(:video_subject).where(subject_video_id: sv.id).order('RANDOM()').first.value
									yv_title << client_names[rand(0..client_names.size-1)]
									yv_title << video_subject_name
									yv_title << yc.google_account.email_account.location.formatted_name
									puts "youtube video title: #{yv_title.join(' ')}"

									blended_video_file = VideoTools::VideoBlender.new(videos: chunks).blend
									blended_video.file = blended_video_file
									blended_video.save!

									youtube_video = yc.generate_video
									youtube_video.title = yv_title.join(' ')
									youtube_video.video = blended_video_file
									youtube_video.blended_video_id = blended_video.id
									youtube_video.save!
								end
							end
						end
					rescue Exception => e
						FileUtils.rm_rf tmp_folder_name
						raise e
					end
				end
			end

		end
	end
end
