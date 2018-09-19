ActiveAdmin.register BroadcastStream do
	menu :parent=>'Broadcasting'

	filter :source_video, as: :select, collection: SourceVideo.order("video_file_name")
	filter :id
	filter :is_active

 	index do
	    selectable_column
	    column :id
	    column 'Source Video' do |broadcast_stream|
	      broadcast_stream.source_video.video_file_name
	    end
	    column 'Video type' do |broadcast_stream|
	    	broadcast_stream.source_video.video_type
	    end
	    column :is_active
	    column :created_at
	    actions
  	end

  	form do |f|
	    f.inputs do 
	      f.input :source_video_id, :as=>:select, collection: f.object.new_record? ? BroadcastStream.available_source_videos : SourceVideo.order(:video_file_name)
	      f.input :is_active
	    end
	    f.actions
  	end

	controller do
		def permitted_params()
			params.permit(broadcast_stream: [:source_video_id, :is_active])
		end
	end
end
