class Templates::Images::VideoThumbnailGenerator
	include ::Templates::Images::VideoThumbnailSettings
	MIN_IMG_WIDTH = 700
	MIN_IMG_ASPECT_RATIO = 0.5
	#Templates::Images::VideoThumbnailGenerator.random_youtube_video_thumbnail(123, custom_texts: {client: ['Client', 'Mr. Client'], bridge_to_sub_text: ['presents'], video_subject:['Video subject']})
	def self.random_youtube_video_thumbnail(youtube_video_id, custom_texts = {})
		youtube_video = YoutubeVideo.find(youtube_video_id)
		blended_video = youtube_video.blended_video
		client = blended_video.source_video.client
		location = blended_video.location

		thumbnail = THUMBNAILS.keys.shuffle.first

		thumb_params = {}

		cdsv = client.client_donor_source_videos.where(recipient_source_video_id: blended_video.source_video.id).first
		donor_source_video ||= cdsv.try(:source_video)

		if image_options = THUMBNAILS[thumbnail][:images]
			img_scope = Artifacts::Image.
				downloaded.
				where.not(file_content_type: 'image/svg+xml').
				where("is_active IS NOT FALSE").
				where("is_special IS NOT TRUE").
				with_aspect_ratio(MIN_IMG_ASPECT_RATIO, MIN_IMG_WIDTH).
				order('RANDOM()')

			if client_images = image_options[:client]
				rand_client_images = if donor_source_video.nil?
															img_scope.where(client_id: client.id).limit(client_images.size)
														else
															img_scope.where("client_id = ? OR client_id = ?", client.id, donor_source_video.client.id).limit(client_images.size)
														end

				raise "Current client with ID=#{client.id} doesn't have enough client images. #{client_images.size - rand_client_images.size} are missing" if rand_client_images.size < client_images.size

				rand_client_images.each_with_index do |img, index|
					thumb_params[client_images[index].to_sym] = img.file.path
				end
			end

			if location_images = image_options[:location]
				rand_loc_images = img_scope.with_location(location, 5).limit(location_images.size) #select images from top 5 cities sorted by population

				if rand_loc_images.to_a.size < location_images.size && location.is_a?(Geobase::Locality)
					Geobase::Locality.where.not(id: location.id).where(id: location.ids_by_radius(20)).order('RANDOM()').each do |radius_loc|
						limit = location_images.size - rand_loc_images.to_a.size
						rand_loc_images = rand_loc_images + img_scope.with_location(radius_loc).limit(limit)

						break if location_images.size == rand_loc_images.to_a.size
					end
				end

				raise "Location doesn't have any image" unless rand_loc_images.any?

				rand_loc_images.each_with_index do |img, index|
					thumb_params[location_images[index].to_sym] = img.file.path
				end
			end
		end

		if text_options = THUMBNAILS[thumbnail][:texts]
			[:location, :client, :bridge_to_sub_text, :video_subject].each do |t|
				if text_options.has_key? t
					t_value = if !custom_texts.blank? && !custom_texts[t].blank?
											custom_texts[t].shuffle.first
										else
											Templates::AaeProjectDynamicTextService.select_texts(t.to_s, blended_video.source_video, location: location, length_threshold: 20).shuffle.first
										end
					thumb_params[THUMBNAILS[thumbnail][:texts][t]] = "#{thumb_params[THUMBNAILS[thumbnail][:texts][t]].to_s} #{t_value.to_s}"
				end
			end
		end

		"RmagickTemplates::#{thumbnail.to_s}".constantize.new(thumb_params).render
	end
end
