class DeleteYoutubeVideo < ActiveRecord::Base
	has_one :api_operation, as: :operation, dependent: :destroy

	belongs_to :upload_youtube_video, foreign_key: :upload_video_operation_id

	validates :youtube_video_id, presence: true

	def self.create(youtube_video)
		deletion_operation = DeleteYoutubeVideo.new
		deletion_operation.youtube_video_id = youtube_video.id
		deletion_operation.save()

		ApiOperation.create({:operation_id=>delete_operation.id,
			operation_type: deletion_operation.class.name,
			broadcast_stream_id: youtube_video.upload_youtube_video.api_operation.broadcast_stream.id,
			google_account_id: youtube_video.upload_youtube_video.api_operation.google_account.id,
			status: 1})
	end
	
	def success(job)
		self.api_operation.update(status:2)
	end

	def error(job)
		self.api_operation.update(status:3)
	end

	def perform()
		client = self.api_operation.google_account.get_google_api_client()
	    client.authorization.fetch_access_token!		
     	
	    ApiOperation.create({:operation_id=>upload_operation.id,
			operation_type: upload_operation.class.name,
			broadcast_stream_id: broadcast_stream.id,
			google_account_id: google_account.id,
			status: 1})

	    youtube = client.discovered_api('youtube', 'v3')

		deletion_result = client.execute!(
		  	:api_method => @youtube.videos.delete,
		  	:parameters => {
		    'id' => youtube_id})
	end
end
