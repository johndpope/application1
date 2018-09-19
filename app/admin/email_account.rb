ActiveAdmin.register EmailAccount do
  filter :client_id, collection: Client.order(:name)

  form do |f|
    f.inputs "Details" do
      f.input :firstname, as: :string
      f.input :lastname, as: :string
      f.input :password
      f.input :email
      f.input :email_item_type, as: :select, collection: ['GoogleAccount']
      f.input :email_item_id, label: 'Email Item ID'
      f.input :gender, label: 'Gender', as: :select, collection: EmailAccount::GENDERS, selected: (f.object.gender.blank? ? nil : f.object.gender.value)
    end
    f.actions
  end

  permit_params :firstname, :lastname, :email, :client_id, :email_item_type, :email_item_id, :gender

end
