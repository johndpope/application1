ActiveAdmin.register ApiApplication do

  show do
    attributes_table do
      row :id
      row :client_id
      row :client_secret
      row 'OAuth' do |api_application|
        link_to 'regenerate token',media_soundcloud_oauth_path(api_application.id)
      end
      row :callback_url
      row :access_token
      row :application_type
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end

  form do |f|
    f.inputs 'Admin Details' do
      f.input :client_id, :label=>'Client ID'
      f.input :client_secret, as: :string
      f.input :callback_url
      f.input :access_token, as: :string
      f.input :application_type, as: :select
    end
    f.actions
  end

  controller do
    def permitted_params
      params.permit(
        api_application: [
          :client_id,
          :client_secret,
          :callback_url,
          :access_token,
          :application_type
        ]
      )
    end
  end

end
