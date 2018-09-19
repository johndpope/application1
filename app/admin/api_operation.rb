ActiveAdmin.register ApiOperation do
	menu parent: 'Broadcasting'
	
	index do
	    selectable_column
	    column :id
	    column :operation_type
	    column 'Operation ID' do |api_operation| 
	    	api_operation.operation_id
	    end
	    column 'Google account' do |api_operation|
	    	api_operation.google_account.email
	    end
	    column :status
	    column :created_at
	    actions
  	end

  	controller do
  		def permitted_params()
  			params.permit api_operation: [
  				:operation_type,
  				:operation_id,
  				:status
  			]
  		end
  	end
end
