class BlendedVideoService
	BASE_DIR = "/tmp/broadcaster/dynamic_video_set_service"

	class << self
		def create_random_blended_video(rendering_machine, client = nil, subject_video = nil, location = nil, track_attributions = true, target = 'distribution')
			rendering_machine = if rendering_machine.is_a? RenderingMachine
				rendering_machine
			elsif rendering_machine.is_a? Integer
				RenderingMachine.find(rendering_machine)
			end

			client = if client.blank?
				Client.where(is_active: true).order('random()').first
			elsif client.is_a? Integer
				Client.find(client)
			elsif client.is_a? Client
				client
			end

			unless client.source_videos_available_for_distribution.exists?
				raise "Client with ID #{client.id} doesn't have source videos available for distribution"
			end

			subject_video = client.source_videos_available_for_distribution.order('RANDOM()').limit(1).first
			available_locations = subject_video.available_distribution_locations
			available_not_empty = available_locations.select{|k,v|v.any?}

			if available_not_empty.empty?
				raise "There are no available distribution locations for source_video with ID #{subject_video.id}"
			end

			location_types = {boroughs: 'Geobase::Locality', cities: 'Geobase::Locality', counties: 'Geobase::Region', states: 'Geobase::Region'}
			rand_loc_type = available_not_empty.keys.sample
			location = location_types[rand_loc_type].constantize.find(available_not_empty[rand_loc_type].sample)

			blending_pattern = BlendingPatternService.random_blending_pattern(subject_video)
			raise "No blending patterns defined" if blending_pattern.blank?

			puts "Generating blended video ..."
			puts "Subject Video: #{subject_video.custom_title}(##{subject_video.id})"
			puts "City: #{location.formatted_name(display_primary_region: true)}"
			puts "Blending Pattern: #{blending_pattern.value}"
			puts "Track Attributions: #{track_attributions}"
			puts "Target: #{target}"
			puts "Generating Dynamic AAE Projects by blending pattern's chunks"

			ActiveRecord::Base.transaction do
				puts "Scheduling blended video ..."
				blended_video = BlendedVideo.create! source_id: subject_video.id,
					location_type: location.class.name,
					location_id: location.id,
					blending_pattern_id: blending_pattern.id
				puts "Scheduling blended video chunks ..."
				blending_pattern_values = blending_pattern.values.reject{|v| v == 'credits'}.reject{|v|v.blank?}
        # hardcoded summary_points part
        if blending_pattern_values.include?('subject')
          blending_pattern_values = blending_pattern_values.reject{|v| v == 'summary_points'}
          blending_pattern_values.insert(blending_pattern_values.index('subject') + 1, 'summary_points')
        else
          blending_pattern_values << 'summary_points' unless blending_pattern_values.include?('summary_points')
        end

        #append logo_transition before credits
        cdsv = subject_video.client.client_donor_source_videos.where(recipient_source_video_id: subject_video.id).first
        donor_source_video ||= cdsv.try(:source_video)
        donor_product = if !donor_source_video.nil?
          donor_source_video.product
        elsif !subject_video.product.parent.nil?
          subject_video.product.parent
        end
        donor_client = donor_product.try(:client)
        certifying_manufacturer = !donor_client.nil? && subject_video.client.certifying_manufacturers.where(id: donor_client.id).exists? ? donor_client : nil
        if (subject_video.client.logo.present? || subject_video.product.present? && subject_video.product.logo.present?) && donor_client.present? && certifying_manufacturer.present? && donor_client.badge_logo.present?
          blending_pattern_values << 'logo_transition'
        end

				#append media credits part at the end of blending pattern
				blending_pattern_values << 'credits'
				blending_pattern_values.each_with_index do |bpv, index|
					chunk_type = (bpv == 'transition' ? %w(simple_transition text_transition image_text_transition).shuffle.first : bpv)
					blended_video_chunk = BlendedVideoChunk.create! blended_video_id: blended_video.id,
						order_nr: (index+1),
						chunk_type: chunk_type

					if bpv != 'subject'
						puts "Scheduling #{bpv} ..."
						aae_project = Templates::AaeTemplateService.random_template(bpv, client.id)
						Delayed::Job.enqueue Templates::DynamicAaeProjects::CreateDynamicAaeProjectJob.new(client.id,
							subject_video.product.id,
							subject_video.id,
							location.id,
							location.class.name,
							aae_project.id,
							target,
							rendering_machine.name,
							rendering_machine.id,
							blended_video_chunk.id), queue: DelayedJobQueue::TEMPLATES_DYNAMIC_AAE_PROJECT_CREATE
					end
				end
			end
		end

		def approve(blended_video_id)
			unless BlendedVideo.joins(:youtube_video).where(id: blended_video_id).exists?
				ActiveRecord::Base.transaction do
					BlendedVideoChunk.where(blended_video_id: blended_video_id).
						without_chunk_type(:subject).
						where("blended_video_chunks.accepted IS NOT true").
						update_all(accepted: true, accepted_automatically: true)
				end
			end
		end

		def blend(video_set_id, target: 'production',
			output_path: nil,
			apply_fading_to_sound: true,
			sound_type: :sound_music,
			instruments: [],
			genres: [],
			moods: [],
			audio_categories: [])
			video_set_dir = File.join(BASE_DIR, "video-set-#{video_set_id}-#{SecureRandom.hex}")
			output_path ||= File.join(video_set_dir, "output.mp4")

			default_fade_time = 1

			FileUtils.mkdir_p video_set_dir

			begin
				ActiveRecord::Base.transaction do
					video_set = BlendedVideo.find(video_set_id)
					#content validation before blending
					if video_set.source_video.nil? && !video_set.source_video.is_virtual?
						raise "Video Set with ID=#{video_set.id} is not associated with Subject Video"
					end
					artifacts_audio_ids_in_use = []

					group_index = 0
					grouped_video_segments = video_set.blended_video_chunks.order(order_nr: :asc).
						chunk{|c|c.chunk_type == 'subject'}.map do |is_subject_group,grouped_segments|
							output_group_video_path = File.join(video_set_dir, "group-%03d-output-video.mp4" % [group_index+1])
							output_group_audio_path = File.join(video_set_dir, "group-%03d-output-audio.mp3" % [group_index+1])
							if is_subject_group
								VideoService.extract_audio(grouped_segments.first.blended_video.source_video.video.path, output_group_audio_path)
								duration = VideoService.get_duration(grouped_segments.first.blended_video.source_video.video.path)
								if apply_fading_to_sound && duration >= (default_fade_time*2 + 0.5)
									VideoService.overlay_fading!(output_group_audio_path, 0, duration - default_fade_time)
								end
								VideoService.overlay_soundtrack(grouped_segments.first.blended_video.source_video.video.path, output_group_audio_path, output_group_video_path, acodec: 'libmp3lame')
							elsif
								group_duration = grouped_segments.sum{|s|VideoService.get_duration(s.dynamic_aae_project.rendered_video.path)}
								tmp_concat_aud_path = File.join(video_set_dir, "group-%03d-tmp-concatenated-audio.mp3" % [group_index+1])
								tmp_concat_vid_path = File.join(video_set_dir, "group-%03d-tmp-concatenated-video.mp4" % [group_index+1])
								cur_duration = 0
								tmp_audios = []
								audio_criteria = {}
								audio_criteria[:genres_id_in] = genres.to_a unless genres.blank?
								audio_criteria[:instrument_in] = instruments.to_a unless instruments.blank?
								audio_criteria[:mood_in] = moods.to_a unless moods.blank?
								audio_criteria[:audio_category_in] = audio_categories.to_a unless audio_categories.blank?
								while cur_duration < group_duration
									if artifacts_audio = Artifacts::YoutubeAudio.ransack(audio_criteria).result.
										where.not(file_file_name: nil).
										where.not("artifacts_audios.id" => artifacts_audio_ids_in_use).
										with_sound_type(sound_type).
										order('RANDOM()').first
											tmp_audios << artifacts_audio.file.path
											audio_duration = VideoService.get_duration(artifacts_audio.file.path)
											cur_duration += audio_duration
									elsif
										raise "There is insufficient number of audios for Video Set with ID=#{video_set_id}"
									end
								end

								VideoService.join_audios(tmp_audios, tmp_concat_aud_path)

								#cuts off soundtrack duration with fade in/fade out filters applied
								%x(ffmpeg -ss 0 -t #{group_duration} -i #{tmp_concat_aud_path} #{output_group_audio_path})
								if apply_fading_to_sound && group_duration >= (default_fade_time*2 + 0.5)
									VideoService.overlay_fading!(output_group_audio_path, 0, group_duration-default_fade_time)
								end

								#joins all grouped video segments into one group video
								VideoService.join_videos(grouped_segments.map{|s|s.dynamic_aae_project.rendered_video.path}, tmp_concat_vid_path)
								#overlays soundtrack on group video
								VideoService.overlay_soundtrack(tmp_concat_vid_path, output_group_audio_path, output_group_video_path, acodec: 'libmp3lame')
							end
							group_index += 1
							{is_subject: is_subject_group, source_segments: grouped_segments, output: output_group_video_path}
					end
					VideoService.join_videos(grouped_video_segments.map{|gvs|gvs[:output]}, output_path)
				end
			rescue Exception => e
				raise e
			ensure
				FileUtils.rm_rf video_set_dir
			end
		end
	end
end
