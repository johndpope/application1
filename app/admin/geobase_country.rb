ActiveAdmin.register Geobase::Country do
  menu parent: 'Geography'
  
  controller do
    def permitted_params
      params.permit(country: [ :primary_region_name, :code, :name, :secondary_region_name, :ternary_region_name, :quaternary_region_name, :region_levels, :woeid ])
    end
  end
  
end
