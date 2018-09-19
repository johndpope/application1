class UploadYoutubeVideo < ActiveRecord::Base
	has_one :api_operation, as: :operation, dependent: :destroy

	YOUTUBE_VIDEO_TAGS_LIMIT = 400
	YOUTUBE_TITLE_LIMIT = 100
	CASE_TYPE_THUMBNAILS_DIR = "#{Rails.root.join('tmp','images','youtube_thumbnails')}"

	def self.create(broadcast_stream,google_account)		
		video_params = generate_video_params(broadcast_stream.source_video, google_account)
		
		upload_operation = UploadYoutubeVideo.new()
		upload_operation.title = video_params[:title]
		upload_operation.description = video_params[:description]
		upload_operation.category_id = broadcast_stream.source_video.category_id if(!broadcast_stream.source_video.category_id.nil?)		
		upload_operation.tags = video_params[:tags]
		upload_operation.save()

		ApiOperation.create({:operation_id=>upload_operation.id,
			operation_type: upload_operation.class.name,
			broadcast_stream_id: broadcast_stream.id,
			google_account_id: google_account.id,
			status: 1})

		return upload_operation
	end

	def self.random_operations(operations_daily_limit,limit)
		ActiveRecord::Base.connection.execute("SELECT random_youtube_video_upload_operations_json(#{operations_daily_limit},#{limit}) AS result")[0]['result']
	end
	
	def success(job)    			    	    	
=begin		
		begin
	    	YoutubeVideo.create(title: self.title,
	    		description: self.description,
	    		youtube_video_id: self.youtube_video_id,    		
	    		youtube_channel_id: self.api_operation.google_account.youtube_channel.id,
	    		source_video_id: self.api_operation.broadcast_stream.source_video.id,
	    		tags: self.tags,
	    		publication_date: self.publication_date).save()	

	    	upload_thumbnail_operation = UploadYoutubeVideoThumbnail.new
			upload_thumbnail_operation.upload_youtube_video_operation_id = self.id		 			 	
			upload_thumbnail_operation.save()

			ApiOperation.create({:operation_id=>upload_thumbnail_operation.id,
				operation_type: upload_thumbnail_operation.class.name,
				broadcast_stream_id: self.api_operation.broadcast_stream_id,
				google_account_id: self.api_operation.google_account_id,
				status: 1})
	    		    	
	    	upload_thumbnail_operation.delay().perform() if self.api_operation.google_account.youtube_channel.thumbnails_enabled   	    	
    	rescue Exception => e
    		puts e.message
    		puts e.backtrace.inspect
    	end
=end    		
  	end

  	def error(job)  		  		
  		#self.update({status: 3})
  	end
	
	def perform()						
=begin		
		client = self.api_operation.google_account.get_google_api_client	    
	    client.authorization.fetch_access_token!
	    	    
	    youtube_video_category_id = self.api_operation.broadcast_stream.source_video.youtube_video_category.youtube_category_id
	    video_file_path = self.api_operation.broadcast_stream.source_video.video.path

	    youtube = client.discovered_api('youtube', 'v3')

	    uploaded_video = client.execute!(
		  api_method: youtube.videos.insert,
		  body_object: {
		    snippet: {
		      title: self.title,
		      description: self.description,
		      categoryId: youtube_video_category_id,		      
		      tags: self.tags ? self.tags.split(',') : []
		    }
		  },
		  media: Google::APIClient::UploadIO.new(video_file_path, 'video/*'),
		  parameters: {
		    'part' => 'snippet',
		    'uploadType' => 'resumable',
		    'alt' => 'json'
		  })
		
	    self.update({youtube_video_id: uploaded_video.data.id, publication_date: uploaded_video.data.snippet.publishedAt})    				    
=end	    
    end	
	
	private	 	

	#TODO refactor this method
	def self.generate_video_params(source_video,google_account)
		video_params = {:title=>'',:description=>'', :tags=>''}

		if(!source_video.case_type_id.nil?)			
			#=====
			#title
			#=====
			title_parts = []

			title_qualifiers_1 = [nil] #optional title parameter
			title_qualifiers_2 = [nil] #optional title parameter
			title_qualifiers_3 = []
			title_tag_lines = [nil] #optional title parameter

			description_qualifiers_1 = []
			description_qualifiers_2 = [] 
			description_qualifiers_3 = []

			Qualifier.select([:name,:level]).where(:is_active=>true,:language_id =>source_video.language_id).each do |q|				
				if(q.level == 1)
					title_qualifiers_1 << q.name 
					description_qualifiers_1 << q.name				
				elsif(q.level == 2)
					title_qualifiers_2 << q.name 
					description_qualifiers_2 << q.name 				
				elsif(q.level == 3)
					title_qualifiers_3 << q.name 
					description_qualifiers_3 << q.name 
				end
			end

			TagLine.select([:name]).where(:is_active=>true).each do |tl|				
				title_tag_lines << tl.name
			end

			title_qualifier_1 = title_qualifiers_1[Random.new.rand(0..(title_qualifiers_1.length>0 ? title_qualifiers_1.length-1 : 0))]
			title_qualifier_2 = title_qualifiers_2[Random.new.rand(0..(title_qualifiers_2.length>0 ? title_qualifiers_2.length-1 : 0))]
			title_qualifier_3 = title_qualifiers_3[Random.new.rand(0..(title_qualifiers_3.length>0 ? title_qualifiers_3.length-1 : 0))]
			title_tag_line = title_tag_lines[Random.new.rand(0..(title_tag_lines.length>0 ? title_tag_lines.length-1 : 0))]
			
			title_parts.push(title_qualifier_1) if(!title_qualifier_1.nil?)
			title_parts.push(title_qualifier_2) if(!title_qualifier_2.nil?)
			title_parts.push(source_video.case_type.name)
			title_parts.push(title_qualifier_3) if(!title_qualifier_3.nil?)
			title_parts.push([google_account.locality.name,google_account.locality.primary_region.name].join(' '))
			
			if(title_tag_line)
				title_parts.push("- #{title_tag_line}") if (title_parts.join(' ').length + title_tag_line.length + 3) <= YOUTUBE_TITLE_LIMIT
			end

			video_params[:title] = title_parts.join(' ')	

			#===========
			#description
			#===========
			description_parts = []

			temp_array = description_qualifiers_1 - [title_qualifier_1]
			description_qualifier_1 = temp_array[Random.new.rand(0..(temp_array.length>0 ? temp_array.length-1 : 0))]
			
			temp_array = description_qualifiers_2 - [title_qualifier_2]
			description_qualifier_2 = description_qualifiers_2[Random.new.rand(0..(description_qualifiers_2.length>0 ? description_qualifiers_2.length-1 : 0))]
			
			description_qualifier_3 = description_qualifiers_3[Random.new.rand(0..(description_qualifiers_3.length>0 ? description_qualifiers_3.length-1 : 0))]
			description_parts.push("http://www.legalbistro.com #{description_qualifier_1.capitalize} #{description_qualifier_2.downcase} #{source_video.case_type.name.downcase} #{description_qualifier_3.downcase} #{google_account.locality.name} #{google_account.locality.primary_region.name}.")

			description_qualifier_1 = description_qualifiers_1[Random.new.rand(0..(description_qualifiers_1.length>0 ? description_qualifiers_1.length-1 : 0))]						
			description_qualifiers_3 = [{:qualifier=>'lawyer',:article=>'a'},{:qualifier=>'attorney',:article=>'an'}]
			description_qualifier_3 = description_qualifiers_3[Random.new.rand(0..(description_qualifiers_3.length>0 ? description_qualifiers_3.length-1 : 0))]
			description_parts.push("If you are looking to #{description_qualifier_1.downcase} #{description_qualifier_3[:article]} #{description_qualifier_3[:qualifier]} in #{google_account.locality.name}, #{google_account.locality.primary_region.name} to handle your #{source_video.case_type.name.downcase}, our video will help you to better understand how to choose the right law firm for your case.\n")
			
			description_parts.push("#{source_video.custom_description}\n") if(!source_video.custom_description.nil?)

			description_parts.push('Visit our blog on http://blog.legalbistro.com/')
			description_parts.push('See us on Facebook: https://www.facebook.com/legalbistropage')
			description_parts.push('See us on Twitter: https://twitter.com/blogLegalBistro')
			description_parts.push('See us on LinkedIn: http://www.linkedin.com/profile/view?id=211696188&authType=name&authToken=FnxO&trk=wvmx-profile-title')
			description_parts.push('See us on Google+: https://plus.google.com/104548476571730466746/posts')
			description_parts.push('Watch our "Why Consumers Love legal Bistro" Video: https://www.youtube.com/watch?v=LdeffI-LJXs')
			description_parts.push('Watch our "Legal Bistro - How It Works" Video: https://www.youtube.com/watch?v=s0rvFx-C66g')

			video_params[:description] = description_parts.join("\n")

			video_params[:tags] = source_video.case_type.get_random_tags(YOUTUBE_VIDEO_TAGS_LIMIT,'en',70,'es',30).join(',')
		end

		return video_params
	end
end
