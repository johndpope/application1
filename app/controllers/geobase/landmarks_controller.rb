module Geobase
	class LandmarksController < Geobase::BaseController
    skip_before_filter :verify_authenticity_token, :only => [:save]

    def save
      json = JSON.load(request.body.read)
      prms = params.merge(json)
      description = prms[:description]
      description_url = prms[:description_url]
      description_type = prms[:description_type]
      landmark_params = {
        name: prms[:name],
        locality_id: prms[:locality_id],
        latitude: prms[:latitude],
        longitude: prms[:longitude],
        category: prms[:category],
        subcategory: prms[:subcategory],
        address: prms[:address],
        phone_number: prms[:phone_number],
        website: prms[:website],
        source_url: prms[:source_url]
      }
      landmark_params.delete_if {|k,v| v.blank?}
      landmark = nil
      saved = if landmark_params[:name] && landmark_params[:locality_id].present? && landmark_params[:category].present?
        landmark = Geobase::Landmark.where("LOWER(name) = ? AND locality_id = ? AND category = ? AND (subcategory IS NULL OR subcategory = ?)", landmark_params[:name].downcase, landmark_params[:locality_id].to_i, landmark_params[:category], landmark_params[:subcategory]).first
        if landmark.present?
          landmark_params.delete(:subcategory) if landmark.subcategory.present?
          landmark.update_attributes(landmark_params) ? true : false
        else
          landmark = Geobase::Landmark.create(landmark_params) ? true : false
        end
      else
        false
      end

      if saved && description.present? && landmark.present? && description_type.present?
        wording = Wording.where(name: description_type, source: description, resource: landmark).first_or_initialize
        wording.url = description_url || landmark_params[:source_url]
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
