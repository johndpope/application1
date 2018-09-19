ActiveAdmin.register VideoScript do
	menu parent:'Source Videos'

 	config.sort_order = "title_asc"

	index do		
		div id: 'preview_dialog', title: 'Preview Video Script' do
			div id: 'content_wrapper'
		end

	    selectable_column
	    column :id    
	    column max_width: '100px' do |video_script|
	    	link_to 'preview', 'javascript://', class: 'preview-video-script', :'data-id'=> video_script.id
	    end
	    column :title
	    column :id_approved	    
	    actions 
  	end

	show do
		attributes_table do
	      row :id      
	      row :title
	      row :is_approved	      
	      row :body do |video_script|
	      	text_node video_script.body.html_safe
	      end
	      row :created_at
	      row :updated_at
	    end
	    active_admin_comments
	end

	form partial: 'video_script_form'

	controller do
		def permitted_params()
			params.permit(video_script: [:title, :body, :is_approved, :notes])
		end
	end
end
