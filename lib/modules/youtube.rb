require 'json'

module Youtube
	#TODO refactor
	def self.upload_videos(daily_limit,limit)		
		json_str = UploadYoutubeVideo::random_operations(daily_limit,limit)		
		json_operations = JSON.parse(json_str)		
		if(!json_operations["operations"].empty?)
			json_operations["operations"].each do |operation|
				api_operation = ApiOperation.where({google_account_id: operation['google_account_id'], 
					broadcast_stream_id: operation['broadcast_stream_id'],
					operation_type: 'UploadYoutubeVideo'})
				if(!api_operation.exists?)
					google_account = GoogleAccount.find(operation['google_account_id'])
					broadcast_stream = BroadcastStream.find(operation['broadcast_stream_id'])
					upload_youtube_video = UploadYoutubeVideo.create(broadcast_stream,google_account)
					upload_youtube_video.delay().perform()
					puts "source video: #{broadcast_stream.source_video.video_file_name}, google account: #{google_account.email}"
				end

			end
		else
			puts 'No active videos to upload'
		end
	end

	def self.upload_video(account_daily_video_limit, datetime)		
		json_str = UploadYoutubeVideo::random_operations(account_daily_video_limit,1)		
		json_operations = JSON.parse(json_str)		
		if(!json_operations["operations"].empty?)
			operation = json_operations["operations"].first
			api_operation = ApiOperation.where({google_account_id: operation['google_account_id'], 
				broadcast_stream_id: operation['broadcast_stream_id'],
				operation_type: 'UploadYoutubeVideo'})
			if(!api_operation.exists?)
				google_account = GoogleAccount.find(operation['google_account_id'])
				broadcast_stream = BroadcastStream.find(operation['broadcast_stream_id'])
				upload_youtube_video = UploadYoutubeVideo.create(broadcast_stream,google_account)
				upload_youtube_video.delay(scheduled_at: datetime).perform()				
			end			
		else
			puts 'No active videos to upload'
		end
	end

	def self.get_duplicates()		
	    GoogleAccount.where('is_active is true').each do |google_account|
	    	client = google_account.get_google_api_client()
	    	client.authorization.fetch_access_token!
	    	youtube = client.discovered_api('youtube','v3')

	    	channels_response = client.execute!(
			  :api_method => youtube.channels.list,
			  :parameters => {
			    :mine => true,
			    :part => 'contentDetails'
			  }
			)

			channels_response.data.items.each do |channel|
			  # From the API response, extract the playlist ID that identifies the list
			  # of videos uploaded to the authenticated user's channel.
			  uploads_list_id = channel['contentDetails']['relatedPlaylists']['uploads']

			  # Retrieve the list of videos uploaded to the authenticated user's channel.
			  playlistitems_response = client.execute!(
			    :api_method => youtube.playlist_items.list,
			    :parameters => {
			      :playlistId => uploads_list_id,
			      :part => 'snippet',
			      :maxResults => 50
			    }
			  )

			  puts "Videos in list #{uploads_list_id}"

			  # Print information about each video.
			  playlistitems_response.data.items.each do |playlist_item|
			    title = playlist_item['snippet']['title']
			    video_id = playlist_item['snippet']['resourceId']['videoId']

			    #puts "#{title} (#{video_id})"
			    puts playlist_item['snippet']['resourceId'].to_json
			  end

			  puts
			end
	    end
	end

	def self.delete_videos()
		DeleteYoutubeVideo.all().each {|deletion_operation| deletion_operation.perform()}
	end

	def self.video_statistics()
		@statistics = GoogleAccount.statistics()		
	end
end