module Geobase
	class CountriesController < Geobase::BaseController
		def index
			search = Country.search(params).result

			respond_to do | format |
				format.json do
					render json: {
						total: search.count,
						items: search.page(params[:page]).per(params[:per_page])
					}
				end
			end
		end
	end
end
