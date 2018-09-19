module Geobase
	class NeighbourhoodsController < Geobase::BaseController
    def save
      json = JSON.load(request.body.read)
      prms = params.merge(json)
      description = prms[:description]
      description_url = prms[:description_url]
      description_type = prms[:description_type]
      neighbourhood_params = {
        name: prms[:name],
        locality_id: prms[:locality_id],
        latitude: prms[:latitude],
        longitude: prms[:longitude],
        source_url: prms[:source_url]
      }
      neighbourhood_params.delete_if {|k,v| v.blank?}
      neighbourhood = nil
      saved = if neighbourhood_params[:name] && neighbourhood_params[:locality_id].present?
        neighbourhood = Geobase::Neighbourhood.where("LOWER(name) = ? AND locality_id = ?", neighbourhood_params[:name].downcase, neighbourhood_params[:locality_id].to_i).first
        if neighbourhood.present?
          neighbourhood.update_attributes(neighbourhood_params) ? true : false
        else
          neighbourhood = Geobase::Neighbourhood.create(neighbourhood_params)
          neighbourhood.id.present? ? true : false
        end
      else
        false
      end

      if saved && description.present? && neighbourhood.present? && description_type.present?
        wording = Wording.where(name: description_type, source: description, resource: neighbourhood).first_or_initialize
        wording.url = description_url || neighbourhood_params[:source_url]
        saved = wording.save
      end

      if saved
        render json: {status: 200}, status: 200
      else
        render json: {status: 500}, status: 500
      end
    end
	end
end
