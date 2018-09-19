ActiveAdmin.register DeleteYoutubeVideo do
	menu parent: 'Broadcasting'

	form do |f|
	  	f.inputs 'Deletion operation' do
	  		f.input :youtube_video_id, :as=>:string, :label=>'Youtube Video ID (Example: ubNk6iSOYC0)'
	  		f.input :upload_video_operation_id, :label=>'Upload Operation ID'
	  		f.input :is_video_duplicate
	  	end
	  	f.actions
  	end

	controller do
	  	def permitted_params
	  		params.permit(:delete_youtube_video=>[:upload_video_operation_id, :youtube_video_id, :is_video_duplicate])
	  	end
	end
end
