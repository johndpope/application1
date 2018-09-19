module YoutubeApiService
	YOUTUBE_G_PLUS_SCOPES = [
		#youtube
		'https://www.googleapis.com/auth/youtube',
		'https://www.googleapis.com/auth/youtube.force-ssl',
		'https://www.googleapis.com/auth/youtube.readonly',
		'https://www.googleapis.com/auth/youtube.upload',
		'https://www.googleapis.com/auth/youtubepartner',
		'https://www.googleapis.com/auth/youtubepartner-channel-audit',
		#youtube analytics
		'https://www.googleapis.com/auth/yt-analytics-monetary.readonly',
		'https://www.googleapis.com/auth/yt-analytics.readonly',
		#google+
		'https://www.googleapis.com/auth/plus.login',
		'https://www.googleapis.com/auth/userinfo.email',
		'https://www.googleapis.com/auth/userinfo.profile',
		'https://www.googleapis.com/auth/plus.me',
		'https://www.googleapis.com/auth/plus.circles.read',
		'https://www.googleapis.com/auth/plus.circles.write',
		'https://www.googleapis.com/auth/plus.media.upload',
		'https://www.googleapis.com/auth/plus.profiles.read',
		'https://www.googleapis.com/auth/plus.stream.read',
		'https://www.googleapis.com/auth/plus.stream.write'
	].join(' ')
	VIDEO_TITLE_LIMIT = 100
	VIDEO_DESCRIPTION_LIMIT = 5000
	VIDEO_TAGS_LIMIT = 500
	LICENSES = {creative_common: 'creativeCommon', youtube: 'youtube'}
	PRIVACY_STATUSES = {public:'public', private:'private', unlisted:'unlisted'}
	CATEGORIES = {"Film & Animation" => 1,
		"Autos & Vehicles" => 2,
		"Music" => 10,
		"Pets & Animals" => 15,
		"Sports" => 17,
		"Short Movies" => 18,
		"Travel & Events" => 19,
		"Gaming" => 20,
		"Videoblogging" => 21,
		"People & Blogs" => 22,
		"Comedy" => 23,
		"Entertainment" => 24,
		"News & Politics" => 25,
		"Howto & Style" => 26,
		"Education" => 27,
		"Science & Technology" => 28,
		"Nonprofits & Activism" => 29,
		"Movies" => 30,
		"Anime/Animation" => 31,
		"Action/Adventure" => 32,
		"Classics" => 33,
		"Comedy" => 34,
		"Documentary" => 35,
		"Drama" => 36,
		"Family" => 37,
		"Foreign" => 38,
		"Horror" => 39,
		"Sci-Fi/Fantasy" => 40,
		"Thriller" => 41,
		"Shorts" => 42,
		"Shows" => 43,
		"Trailers" => 44
	}
	THUMB_MIN_WIDTH = 800
	THUMB_MIN_HEIGHT = 600

	def self.get_authorized_api_client
		client = Google::APIClient.new(application_name:CONFIG['google']['app_name'], application_version:CONFIG['google']['app_version'])
    client.authorization.client_id = CONFIG['youtube']['app_id']
    client.authorization.client_secret = CONFIG['youtube']['app_secret']
    client.authorization.redirect_uri = CONFIG['youtube']['sandbox_redirect_uri']
    client.authorization.scope = YOUTUBE_G_PLUS_SCOPES
		client
	end

	def self.genetate_google_plus_and_youtube_oauth_request_link(redirect_uri)
		client = get_authorized_api_client
		client.authorization.authorization_uri.to_s
	end

	def self.get_refresh_token(authorization_code)
		client = get_authorized_api_client
    client.authorization.code = authorization_code
    api_response = client.authorization.fetch_access_token!
		api_response['refresh_token']
	end

	def self.get_youtube_channel_info(refresh_token)
		client = get_authorized_api_client
		client.authorization.refresh_token = refresh_token
		client.authorization.fetch_access_token!
		youtube = client.discovered_api('youtube', 'v3')
		api_response = client.execute key: CONFIG['youtube']['api_key'], api_method: youtube.channels.list, parameters: {mine:true, part:'id,snippet'}
		channel_info = JSON.parse(api_response.response.body)['items'].to_a.first
		{
			id: channel_info['id'],
			avatar_url: channel_info['snippet']['thumbnails']['default']['url'],
			title: channel_info['snippet']['title'],
			url: get_youtube_channel_url(channel_info['id'])
		}
	end

	def self.get_google_account_info(refresh_token)
		client = get_authorized_api_client
		client.authorization.refresh_token = refresh_token
		client.authorization.fetch_access_token!

		 google_plus_api_client = Google::APIClient.new.discovered_api('plus', 'v1')
		 api_response = client.execute key: CONFIG['youtube']['api_key'],
		 	api_method: google_plus_api_client.people.get,
      parameters: {'userId' => 'me'}
		 json = JSON.parse(api_response.response.body)

		 google_account_info = {email:nil,
			 first_name:nil,
			 last_name:nil,
			 google_plus_profile_url:nil,
			 google_plus_profile_image_url:nil}

		 if email_info = json['emails'].select{|email|email['type'] == 'account'}.first
			 google_account_info[:email] = email_info['value']
		 end
		 if initials = json['name']
		 	google_account_info[:first_name] = initials['givenName']
			google_account_info[:last_name] = initials['familyName']
		 end
		 google_account_info[:google_plus_profile_url] = json['url'] unless json['url'].blank?
		 if gplus_image_info = json['image']
			 google_account_info[:google_plus_profile_image_url] = gplus_image_info['url']
		 end

		 google_account_info
	end

	def self.get_youtube_channel_url(channel_id)
		"https://www.youtube.com/channel/#{channel_id}"
	end

	def self.upload_video(refresh_token, options = {})
		defaults = {
			category:22, #Peoples & Blogs
			privacy_status: :public,
			license: :youtube,
			is_embeddable: true
		}
		video_options = defaults.merge(options)
		raise 'Title cannot be blank' if video_options[:title].blank?
		raise 'Title length is exceeded' if video_options[:title].length > VIDEO_TITLE_LIMIT
		raise 'Description cannot be blank' if video_options[:description].blank?
		raise 'Description length is exceeeded' if video_options[:description].length > VIDEO_DESCRIPTION_LIMIT
		tags = if video_options[:tags].is_a? String
			video_options[:tags].to_s.split(/\s*,\s*/).reject{|e|e.blank?}.map{|e|e.strip}
		elsif video_options[:tags].is_a? Array
			video_options[:tags].reject{|e|e.blank?}.map{|e|e.strip}
		else
			[]
		end
		raise 'Tags length is exceeded' if video_options[:tags].to_a.join(',').length > VIDEO_TAGS_LIMIT
		raise "Invalid video category value" unless CATEGORIES.values.include? video_options[:category]
		raise "Invalid privacy status value" unless PRIVACY_STATUSES.keys.include? video_options[:privacy_status]
		raise "Invalid license value" unless LICENSES.keys.include? video_options[:license]
		raise 'Video file path cannot be blank' if video_options[:video_file_path].blank?
		raise "Video file path doesn't exist" unless File.exists? video_options[:video_file_path]

		# fix Errno::EPIPE: Broken pipe exception
		Faraday.default_adapter = :httpclient

		google_api_client = get_authorized_api_client()
		google_api_client.authorization.scope = 'https://www.googleapis.com/auth/youtube.upload'
		google_api_client.authorization.refresh_token = refresh_token
		google_api_client.authorization.fetch_access_token!

		youtube_api_client = google_api_client.discovered_api('youtube', 'v3')
		body_object = {
			snippet: {
				title: video_options[:title],
				description: video_options[:description],
				categoryId: video_options[:category].to_s,
				tags: tags
			},
			status:{
				license: LICENSES[video_options[:license]],
				privacyStatus: PRIVACY_STATUSES[video_options[:privacy_status]],
				embeddable: video_options[:is_embeddable]
			}
		}

		uploaded_video = google_api_client.execute!(
			api_method: youtube_api_client.videos.insert,
			body_object: body_object,
			media: Google::APIClient::UploadIO.new(video_options[:video_file_path], 'video/*'),
			parameters: {
				'part' => body_object.keys.join(','),
				'uploadType' => 'resumable',
				'alt' => 'json'
			}
		)

		uploaded_video
	end

	def self.upload_video_thumbnail(refresh_token, youtube_video_id, thumbnail_file_path)
		raise "Thumbnail file path doesn't exist" unless File.exists? thumbnail_file_path
		thumb_content_type = FastImage.type thumbnail_file_path
		available_content_types = %w(jpg jpeg png)
		raise "Thumbnail media type is not supported. It should be [#{available_content_types.joins(', ')}]" unless available_content_types.include?(thumb_content_type.to_s)
		thumb_size = FastImage.size thumbnail_file_path
		if thumb_size.first < THUMB_MIN_WIDTH || thumb_size.last < THUMB_MIN_HEIGHT
			raise "Thumbnail size doesn't match minimal resolution in 800x600 pixels"
		end

		# fix Errno::EPIPE: Broken pipe exception
		Faraday.default_adapter = :httpclient

		google_api_client = get_authorized_api_client()
		google_api_client.authorization.scope = 'https://www.googleapis.com/auth/youtube'
		google_api_client.authorization.refresh_token = refresh_token
		google_api_client.authorization.fetch_access_token!

		youtube_api_client = google_api_client.discovered_api('youtube', 'v3')

		api_response = google_api_client.execute!(
			api_method: youtube_api_client.thumbnails.set,
			media: Google::APIClient::UploadIO.new(thumbnail_file_path, "image/#{thumb_content_type}"),
			parameters: {videoId:youtube_video_id, 'uploadType' => 'media', 'alt' => 'json'},
			headers: {'Content-Length'=>File.size(thumbnail_file_path).to_s}
		)

		api_response
	end
end
