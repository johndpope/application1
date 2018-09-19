ActiveAdmin.register CaseTag do
	menu parent: 'Source Videos'

	filter :case_type
	filter :language
	filter :name

	index do
	    selectable_column
	    column :id
	    column :name 
	    column :case_type 
	    column :language
	    actions 
  	end

	controller do
	    def permitted_params
	      params.permit(case_tag: [:name, 
	        :language_id,
	        :case_type_id])
	    end
  end
end
