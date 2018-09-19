ActiveAdmin.register GoogleApiProject do
	menu parent: 'Google'

	filter :name
	filter :number
	filter :google_account_id	
	filter :created_at
	filter :updated_at

	index do
	    selectable_column
	    column :id
	    column :name
	    column :number
	    column :google_account	    
	    column :created_at
	    column :updated_at
	    actions
  	end

	form do |f|
	    f.inputs 'Admin Details' do
	      f.input :google_account_id, :label=>'Google Account ID'
	      f.input :name
	      f.input :number      
	    end
	    f.actions
  	end

  	controller do
	    def permitted_params
	      params.permit(
	        google_api_project: [
	          :google_account_id,
	          :name,
	          :number          
	        ]
	      )
	    end
  	end

end
