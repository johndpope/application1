ActiveAdmin.register GoogleApiClient do
	menu parent: 'Google'

	index do
	    selectable_column
	    column :id
	    column :google_api_project
	    column :client_id
	    column :client_secret
	    column :email_address
	    column :created_at
	    column :updated_at
	    actions
  	end

  	show do
	    attributes_table do
	      row :id	      
	      row :google_api_project
	      row :client_id
	      row :client_secret
	      row :email_address
	      row :redirect_uris
	      row :javascript_origins	      
	      row :created_at
	      row :updated_at
	    end
	    active_admin_comments
  	end

	form do |f|
	    f.inputs 'Admin Details' do
		  f.input :google_api_project_id, as: :select, :collection=>GoogleApiProject.order(:name)
	      f.input :client_id, :label=>'Client ID'
	      f.input :client_secret, as: :string
	      f.input :email_address, as: :string
	      f.input :redirect_uris
	      f.input :javascript_origins      
	    end
	    f.actions
  	end

  	controller do
	    def permitted_params
	      params.permit(
	        google_api_client: [
	          :google_api_project_id,
	          :client_id,
	          :client_secret,
	          :email_address,
	          :redirect_uris,
	          :javascript_origins          
	        ]
	      )
	    end
  	end
end
