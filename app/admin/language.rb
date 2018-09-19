ActiveAdmin.register Language do
	menu parent: 'Source Videos'
	
	controller do    
	    def permitted_params
	      params.permit(:language => [:name, :code])
	    end
  end
end
