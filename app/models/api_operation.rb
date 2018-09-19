class ApiOperation < ActiveRecord::Base
	OPERATION_TYPES = ['UploadYoutubeVideo', 'UploadYoutubeVideoThumbnail', 'DeleteYoutubeVideo']
	
	extend Enumerize
	enumerize :status, :in=>{1=>:in_progress, 2=>:succeeded, 3=>:failed}
	
	belongs_to :operation, :polymorphic=>true	
	belongs_to :google_account, foreign_key: :google_account_id
	belongs_to :broadcast_stream, foreign_key: :broadcast_stream_id
	
end
