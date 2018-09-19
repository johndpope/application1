ActiveAdmin.register TechnicalAccount do

  index do
    selectable_column
    column :id    
    column :name
    column :password
    column 'description' do |technical_account|
      simple_format technical_account.description
    end        
    actions 
  end

  show do
    attributes_table do
      row :id      
      row :name
      row :password
      row 'description' do 
        simple_format technical_account.description
      end
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end

  form do |f|
    f.inputs "Details" do                   
      f.input :name, as: :string
      f.input :password, as: :string
      f.input :description
    end
    f.actions
  end
  
  permit_params do
      permitted = [:name, :password, :description]      
      permitted
  end

  controller do
    #load_and_authorize_resource
  end
  
end
