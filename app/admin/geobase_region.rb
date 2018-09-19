ActiveAdmin.register Geobase::Region do
  menu parent: 'Geography'

  filter :country
  filter :parent
  filter :code
  filter :name
  filter :level
  filter :created_at
  filter :updated_at

  

  controller do
    def permitted_params
      params.permit(region: [ :country_id, :parent_id, :code, :name, :level, :coordinates ])
    end
  end
end
