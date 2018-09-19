ActiveAdmin.register Qualifier do
	menu parent: 'Source Videos'

	index do
	    selectable_column
	    column :id	    
	    column :name
	    column :level
	    column :language
	    column :is_active
	    column :updated_at	    
	    actions 
  	end

	form do |f|
	    f.inputs 'Qualifier Details' do
	      f.input :name
	      f.input :language, :as=>:select, collection: Language.order(:name), :selected=>Language.find(:first,:conditions=>{:code=>'en'}).id
	      f.input :level
	      f.input :is_active
	    end
	    f.actions
  	end
end
