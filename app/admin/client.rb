ActiveAdmin.register Client do
	menu parent: 'Broadcasting'

	controller do
	    def permitted_params
	      params.permit(
	        client: [
	          :name,
	          :description
	        ]
	      )
	    end
  	end
end
