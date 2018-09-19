ActiveAdmin.register Geobase::ZipCode do
  menu parent: 'Geography'

  filter :code
  filter :latitude
  filter :longitude
  filter :created_at
  filter :updated_at

  form do |f|
    f.inputs 'ZIP Code Details' do
      f.input :primary_region, as: :select, collection: Geobase::Region.where(level: 1).order(:name)
      f.input :secondary_region, as: :select, collection: Geobase::Region.where(level: 2).order(:name)
      f.input :code
      f.input :latitude
      f.input :longitude
    end
    f.actions
  end

  controller do
    def permitted_params
      params.permit(zip_code: [ :primary_region_id, :secondary_region_id, :code, :latitude, :longitude ])
    end
  end
end
