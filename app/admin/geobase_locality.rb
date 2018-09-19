ActiveAdmin.register Geobase::Locality do
  menu parent: 'Geography'

  filter :country
  filter :primary_region, as: :select, collection: Geobase::Region.where(level: 1).order(:name)
  filter :code
  filter :name
  filter :population
  filter :created_at
  filter :updated_at

  form do |f|
    f.inputs 'Locality Details' do
      f.input :primary_region, as: :select, collection: Geobase::Region.where(level: 1).order(:name)
      f.input :code
      f.input :name
      f.input :population
    end
    f.actions
  end

  controller do
    def permitted_params
      params.permit(locality: [ :primary_region_id, :code, :name, :population ])
    end
  end
end
