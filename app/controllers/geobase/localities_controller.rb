module Geobase
	class LocalitiesController < Geobase::BaseController
    skip_before_filter :verify_authenticity_token, :only => [:add_description, :add_info]
    before_action :set_locality, only: [:update]

		def index
			search = Locality.search(params).result
			items = search.page(params[:page]).per(params[:per_page])

			respond_to do | format |
				format.json do
					render json: {
						total: search.count,
						items: JSON.parse(
							items.to_json(
								include: {
									primary_region: { only: [:id, :name, :code] },
									country: { only: [:id, :code, :name] },
									secondary_regions: { only: [:id, :name] }
								},
								methods: :display_name
							)
						)
					}
				end
			end
		end

    def update
      respond_to do | format |
        if @locality.update_attributes(locality_params)
          format.js{render nothing: true}
        else
          format.js{render status: 500}
        end
      end
    end

    def add_description
      @locality = Geobase::Locality.find_by_id(params[:id])
      json = JSON.load(request.body.read)
      prms = params.merge(json)
      if @locality.present?
        saved = if prms[:description].present? && prms[:description_type].present?
          wording = Wording.where(name: prms[:description_type], source: prms[:description], resource: @locality).first_or_initialize
          wording.url = prms[:source_url]
          wording.save
        else
          false
        end
        if saved
          render json: {status: 200}, status: 200
        else
          render json: {status: 500}, status: 500
        end
      else
        render json: {status: 404}, status: 404
      end
    end

    def add_info
      locality = Geobase::Locality.find_by_id(params[:id])
      if locality.present?
        # json_full_path = (Setting.get_value_by_name("EmailAccount::BOT_URL") + Setting.get_value_by_name("Wording::TRIPADVISOR_JSON_PATH")).gsub("<locality_id>", params[:id])
        # Delayed::Job.enqueue Crawler::CrawlerAddInfoJob.new(locality.id, json_full_path), queue: DelayedJobQueue::CRAWLER_ADD_INFO
        render json: {status: 200}
      else
        render json: {status: 404, messages: "Locality with id: #{params[:id]} not found!"}, status: 404
      end
    end

    private
      def locality_params
        params["locality_type"] = nil if params["locality_type"] == "0"
        params.permit(:id, :locality_type, :description, :description_type)
      end

      def set_locality
        @locality = Geobase::Locality.find(params[:id])
      end
	end
end
