class UploadYoutubeVideoThumbnail < ActiveRecord::Base
	has_one :api_operation, :as=>:operation, dependent: :destroy
	belongs_to :upload_youtube_video, foreign_key: :upload_youtube_video_operation_id
	
	CASE_TYPE_THUMBNAILS_DIR = "#{Rails.root.join('tmp','images','youtube_thumbnails')}"

	#TODO refactor
	def perform()
		client = self.api_operation.google_account.get_google_api_client			    
	    client.authorization.fetch_access_token!
	    
	    youtube = client.discovered_api('youtube', 'v3')
		
	    if(!self.api_operation.broadcast_stream.source_video.case_type.nil?)
	 		thumbnail_dir = File.join(CASE_TYPE_THUMBNAILS_DIR,
	 			self.api_operation.google_account.locality.primary_region.name,
				self.api_operation.google_account.locality.name).downcase
	 		
	 		FileUtils.mkdir_p(thumbnail_dir)
	 		system("chmod -R 755 #{CASE_TYPE_THUMBNAILS_DIR}")
	 		
			Thumbnailer::Generator.new(thumbnail_dir,
				self.api_operation.broadcast_stream.source_video.case_type,
				self.api_operation.google_account.locality).generate()			
		end

	    thumbnail_file_path = if(self.api_operation.broadcast_stream.source_video.case_type_id.nil?)
    		self.api_operation.broadcast_stream.source_video.video.path
    	else
    		thumbnail_dir = File.join(CASE_TYPE_THUMBNAILS_DIR,
	 			self.api_operation.google_account.locality.primary_region.name,
				self.api_operation.google_account.locality.name).downcase
    		thumbnail_file_name = "#{[self.api_operation.broadcast_stream.source_video.case_type.name, 
	 			self.api_operation.google_account.locality.name,
	 			self.api_operation.google_account.locality.primary_region.name].join('_')}.png".downcase

 			File.join(thumbnail_dir,thumbnail_file_name)
    	end

	    thumbnail_response = client.execute!(
		  :api_method => youtube.thumbnails.set,
		  :parameters => { :videoId =>self.upload_youtube_video.youtube_video_id,		  	
		    'uploadType' => 'media',
		    'alt' => 'json'},		  
		  :media => Google::APIClient::UploadIO.new(thumbnail_file_path, 'image/png'),
		  :headers => {'Content-Length'=>File.size(thumbnail_file_path).to_s}		  
		)    
	end	
end
