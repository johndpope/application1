module Geobase
	class SearchController < Geobase::BaseController
		def index
			render json: if params[:type].present?
				if !params[:id].present? && !params[:query].present?
					{ error: 'Could not find "id" or "query".' }
				else
					self.send(params[:type].downcase, params)
				end
			else
				{ error: 'Could not find "type".' }
			end
		end

		def country (params = {})
			if params[:query].present?
				Geobase::Country
					.select('id', 'name')
					.where('UPPER(name) LIKE UPPER(?)', "%#{params[:query]}%")
					.limit(100)
			elsif params[:id].present?
				Geobase::Country
					.select('id', 'name')
					.find_by_id(params[:id])
			end
		end

		def state (params = {})
			if params[:query].present?
				Geobase::Region
					.select('id', 'name')
					.where('country_id = ? AND level = 1 AND UPPER(name) LIKE UPPER(?)', params[:country_id], "%#{params[:query]}%")
					.limit(100)
			elsif params[:id].present?
				Geobase::Region
					.select('id', 'name')
					.find_by_id(params[:id])
			end
		end

		def county (params = {})
			if params[:query].present?
				Geobase::Region
					.select('id', 'name')
					.where('country_id = ? AND level = 2 AND parent_id = ? AND UPPER(name) LIKE UPPER(?)', params[:country_id], params[:state_id], "%#{params[:query]}%")
					.limit(100)
			elsif params[:id].present?
				Geobase::Region
					.select('id', 'name')
					.find_by_id(params[:id])
			end
		end

		def locality (params = {})
			if params[:query].present?
				Geobase::Locality
					.select('id', 'name')
					.where('primary_region_id = ? AND UPPER(name) LIKE UPPER(?)', params[:state_id], "%#{params[:query]}%")
					.limit(100)
			elsif params[:id].present?
				Geobase::Locality
					.select('id', 'name')
					.find_by_id(params[:id])
			end
		end

		def landmark (params = {})
			if params[:query].present?
				Geobase::Landmark
					.select('id', 'name')
					.where('locality_id = ? AND UPPER(name) LIKE UPPER(?)', params[:locality_id], "%#{params[:query]}%")
					.limit(100)
			elsif params[:id].present?
				Geobase::Landmark
					.select('id', 'name')
					.find_by_id(params[:id])
			end
		end
	end
end
