module Artifacts
  class ImagesController < BaseController
    IMAGES_COUNT_DEFAULT_LIMIT = 100
    skip_before_filter :verify_authenticity_token, :only => [:reject]
    def index
      @api = params[:api]
      @rejected_images_ids = []
      search = { total: 0, items: [] }
      if request.query_parameters.present?
        params[:limit] = IMAGES_COUNT_DEFAULT_LIMIT unless params[:limit].present?
        if (params[:q].present? || (params[:user_id].present? && @api.titleize == "Flickr")) || @api.blank?
          @rejected_images_ids = Artifacts::RejectedImage.select(:source_id).distinct.where(source_type: "Artifacts::#{@api}Image").pluck(:source_id)
          options = params.merge(
            { q: params[:q], user_id:params[:user_id], page: params[:page], limit: params[:limit], rejected_images_ids: @rejected_images_ids }
          )
          search = "Artifacts::#{@api}Image".constantize.list(options)
          @total_count = search[:total]
        end
        @images = Kaminari.paginate_array(
          search[:items],
          total_count: search[:total]
        ).page(params[:page]).per(params[:limit])
      else
        @images = Kaminari.paginate_array(
          search[:items],
          total_count: search[:total]
        ).page(params[:page]).per(params[:limit])
      end
    end

    def import
      image_class = "Artifacts::#{params[:api]}Image".constantize
      country = params[:country].present? ? Geobase::Country.find(params[:country]) : nil
      region1 = params[:region1].present? ? Geobase::Region.find(params[:region1]) : nil
      region2 = params[:region2].present? ? Geobase::Region.find(params[:region2]) : nil
      city = params[:city].present? ? Geobase::Locality.find(params[:city]) : nil
      industry_id = params[:industry_id].present? ? Industry.find(params[:industry_id]).id : nil
      client_id = params[:client_id].present? ? Client.find(params[:client_id]).id : nil
      use_for_landing_pages = params[:use_for_landing_pages]
      reusable = params[:reusable]
      tags = params[:tag_list].to_s.split(',').map(&:strip).map{|e|e.mb_chars.downcase.to_s}.uniq.reject(&:blank?)
      params[:source_ids].each_with_index do |source_id, index|
        @image = image_class.new(
          source_id: source_id,
          gravity: params[:gravities][index],
          country: country.try(:name),
          region1: region1.try(:name),
          region2: region2.try(:name),
          city: city.try(:name),
          client_id: client_id,
          industry_id: industry_id,
          admin_user_id: current_admin_user.id,
          tag_list: tags,
          reusable: reusable,
          use_for_landing_pages: use_for_landing_pages
        )
        ActiveRecord::Base.connection_pool.with_connection do
          ActiveRecord::Base.transaction do
            @image.save!
            Delayed::Job.enqueue Artifacts::ImageImportJob.new(@image.type, @image.id),
  						queue: DelayedJobQueue::ARTIFACTS_IMAGE_IMPORT,
  						priority: DelayedJobPriority::HIGH
          end
        end
      end
      respond_to do |format|
        format.js{render status: :ok}
      end
    end

    def show
      @image = Image.find(params[:id])
    end

    def edit
      @image = Image.find(params[:id])
      @clients = Client.order(:name)
      respond_to do |format|
        format.js
      end
    end

    def update
      @image = Image.find(params[:id])
      @image.update_attributes(image_params)

      categories_arr = params[:artifacts_image][:categories].blank? ? nil : params[:artifacts_image][:categories].values
      categories = Artifacts::ImageCategory.where(:id => categories_arr)
      @image.update_attributes(:image_categories => categories)

      respond_to do |format|
        format.js
      end
    end

    def gravity
      @image = Image.find(params[:image_id])
      @image.gravity = params[:gravity]
      @image.save!
      respond_to{|format| format.js{render nothing: true}}
    end

    def reject
      if params[:add] == 'false'
        rejected_image = Artifacts::RejectedImage.where(source_id: params[:source_id], source_type: params[:type]).first
        rejected_image.destroy if rejected_image.present?
      else
        Artifacts::RejectedImage.create(source_id: params[:source_id], source_type: params[:type])
      end
      respond_to{|format| format.js{render nothing: true}}
    end

    def aspect_cropping_variations
      @image = Image.find(params[:image_id])
    end

    def destroy
      @image = Image.find(params[:id])
      @image.destroy!
      Artifacts::RejectedImage.create(source_id: @image.source_id, source_type: @image.type) if @image.type.present?
      respond_to do |format|
        format.js
      end
    end

    def region1_coverage
      counts = Artifacts::Image.joins(
        <<-SQL
          RIGHT OUTER JOIN geobase_regions
            ON artifacts_images.region1 = geobase_regions.name
              AND geobase_regions.level = 1
        SQL
      ).group('1').pluck("split_part(geobase_regions.code, '<sep/>', 1), count(artifacts_images.*)") #rollback after region code fix
      respond_to do |format|
        format.json { render json: Hash[counts] }
      end
    end

    def region2_coverage
      #Since we have field geobase_regions.code formatted like code1<sep/>code2<sep/>code3, for instance "US-AL<sep/>\tAL<sep/>Ala.,
      #query Geobase::Region.find_by(code: params[:region1]) will be replaced with temporar solution based on LIKE
      #It should be rolled back after region code refactoring
      region1 = Geobase::Region.where('code LIKE ?', "%#{params[:region1]}%").first #rollback after region code fix
      counts = Artifacts::Image.joins(
        %Q[
          RIGHT OUTER JOIN geobase_regions
            ON artifacts_images.region2 = geobase_regions.name
              AND geobase_regions.parent_id = #{region1.id}
              AND artifacts_images.region1 = '#{region1.name}'
        ]
      ).group('1').pluck("'#{region1.code.to_s.split('<sep/>').first.to_s}' || ' ' || geobase_regions.name || ' ' || 'County', count(artifacts_images.*)") #rollback after region code fix
      respond_to do |format|
        format.json { render json: Hash[counts] }
      end
    end

    def local_import

    end

    def upload
      image_type = params[:special_tags].blank? ? "" : "Icon"
      @image = "Artifacts::#{image_type}Image".constantize.new is_local: true
      @image.file = params[:artifacts_image][:file].first
      file_name = @image.try(:file_file_name).to_s
      title = File.basename(file_name).gsub(File.extname(file_name), '').to_s.humanize
      @image.title = title
      @image.client_id = params[:client_id] unless params[:client_id].blank?
      @image.tag_list = params[:tags].split(',').map(&:strip).uniq unless params[:tags].blank?
      @image.industry_id = params[:industry_id] unless params[:industry_id].blank?
			@image.product_id = params[:product_id] unless params[:product_id].blank?
			unless params[:special_tags].blank?
				tags = []
				params[:special_tags].split(',').each{|t|
					tags << t
					tags << Artifacts::Image::SPECIAL_TAGS[:tag_mappings][t.to_sym] unless Artifacts::Image::SPECIAL_TAGS[:tag_mappings][t.to_sym].blank?
				}
				@image.special_tag_list = tags.flatten.uniq.reject(&:blank?)
				@image.is_special = true unless @image.special_tag_list.blank?
			end
      @image.use_for_landing_pages = params[:use_for_landing_pages] unless params[:use_for_landing_pages].blank?
      %w(country region1 region2 city notes).each do |p|
        @image.send("#{p}=", params[p.to_sym]) unless params[p.to_sym].blank? || params[p.to_sym] == 'undefined'
      end
      %w(reusable broadcaster_property).each do |p|
        @image.send("#{p}=", params[p.to_sym]) if !params[p.to_sym].blank? && %w(true false).include?(params[p.to_sym])
      end
      @image.rating = params[:rating] unless params[:rating].blank?
      @image.category = params[:category] unless params[:category].blank?
      @image.image_categories = Artifacts::ImageCategory.where(:id => params[:image_categories].split(','))

      respond_to do |format|
        if @image.save
          ActiveRecord::Base.transaction do
            Delayed::Job.enqueue Artifacts::ImageAspectCroppingJob.new("Artifacts::Image", @image.id),
							queue: DelayedJobQueue::ARTIFACTS_IMAGE_IMPORT,
							priority: DelayedJobPriority::LOW
						Delayed::Job.enqueue Artifacts::GenerateImageCroppingsJob.new(@image.id),
							queue: DelayedJobQueue::ARTIFACTS_GENERATE_IMAGE_CROPPINGS,
							priority: DelayedJobPriority::LOW
            if @image.file.exists? && !@image.lat.present? && !@image.lng.present?
              Delayed::Job.enqueue Artifacts::RetrieveGpsFromImageFilesJob.new(@image.id),
                queue: DelayedJobQueue::RETRIEVE_GPS_FROM_IMAGE_FILES,
                priority: DelayedJobPriority::LOW
            end
          end
          format.json { render json: {files: [@image.to_jq_upload]}, status: :created, location: artifacts_image_path(@image) }
        else
          format.json { render json: @image.errors, status: :unprocessable_entity }
        end
      end
    end

    def report_by_localities
      params[:locality_type] = Geobase::Locality.locality_type.find_value('City').value unless params.keys.include?("locality_type")
      params[:country] = Geobase::Country.find_by_code("US").id unless params[:country].present?
      params[:limit] = IMAGES_COUNT_DEFAULT_LIMIT unless params[:limit].present?
      params[:images_count_limit] = 100000 unless params[:images_count_limit].present?

      if params[:filter].present?
        params[:filter][:order] = 'population' unless params[:filter][:order].present?
        params[:filter][:order_type] = 'desc' unless params[:filter][:order_type].present?
      else
        params[:filter] = { order: 'population', order_type: 'desc' }
      end

      order_by = if params[:filter][:order] == 'images_count'
        params[:filter][:order]
      else
        'geobase_localities.' + params[:filter][:order]
      end

      params[:locality_type] = nil if params[:city].present?

      locality_type_part = if params[:locality_type].present?
          if params[:locality_type].to_i > 0
            " AND geobase_localities.locality_type = #{params[:locality_type]} "
          else
            " AND geobase_localities.locality_type IS NULL"
          end
        else
          ""
      end

      locality_ids = if params[:city].present?
        params[:city]
      else
        ids = params[:locality_ids].to_s.strip.split(",").map(&:to_i)
        params[:limit] = ids.size if ids.size > 0
        ids.join(",")
      end

      @localities = Geobase::Locality.joins("LEFT OUTER JOIN geobase_regions ON geobase_regions.id = geobase_localities.primary_region_id LEFT OUTER JOIN geobase_countries ON geobase_countries.id = geobase_regions.country_id")
        .select("geobase_localities.*, locality_artifacts_images_count(geobase_localities.id, geobase_localities.name, geobase_localities.primary_region_id) AS images_count, locality_high_res_artifacts_images_count(geobase_localities.id, geobase_localities.name, geobase_localities.primary_region_id) as high_res_images_count")
        .where("locality_artifacts_images_count(geobase_localities.id, geobase_localities.name, geobase_localities.primary_region_id) <= ? #{locality_type_part} AND geobase_localities.population IS NOT NULL AND geobase_countries.id = ?
      #{'AND geobase_localities.id in (' + locality_ids + ')' if locality_ids.present?} #{'AND geobase_regions.id = ' + params[:region1] if params[:region1].present?}", params[:images_count_limit], params[:country])
        .order(order_by + ' ' + params[:filter][:order_type])
        .page(params[:page]).per(params[:limit])
    end

    def report_by_industries
      params[:limit] = IMAGES_COUNT_DEFAULT_LIMIT unless params[:limit].present?
      params[:images_count_limit] = 100000 unless params[:images_count_limit].present?

      if params[:filter].present?
        params[:filter][:order] = 'code' unless params[:filter][:order].present?
        params[:filter][:order_type] = 'asc' unless params[:filter][:order_type].present?
      else
        params[:filter] = { order: 'code', order_type: 'asc' }
      end

      order_by = if %w(images_count short_descriptions_count long_descriptions_count).include?(params[:filter][:order])
        params[:filter][:order] + ' ' + params[:filter][:order_type] + ", industries.code ASC"
      else
        'industries.' + params[:filter][:order] + ' ' + params[:filter][:order_type]
      end

      @industries = Industry.joins("LEFT JOIN wordings ON wordings.resource_id = industries.id AND wordings.resource_type = 'Industry'").distinct.select("industries.*, (SELECT count(artifacts_images.id) FROM artifacts_images WHERE artifacts_images.industry_id = industries.id) AS images_count, (SELECT count(wordings.id) FROM wordings WHERE wordings.resource_id = industries.id AND resource_type = 'Industry' AND name = 'short_description') AS short_descriptions_count, (SELECT count(wordings.id) FROM wordings WHERE wordings.resource_id = industries.id AND resource_type = 'Industry' AND name = 'long_description') AS long_descriptions_count")
        .where("(SELECT count(artifacts_images.id) FROM artifacts_images WHERE artifacts_images.industry_id = industries.id) <= ?", params[:images_count_limit])
        .by_id(params[:industry_id])
        .order(order_by)
        .page(params[:page]).per(params[:limit])
    end

    def report_by_admin_users
      params[:days_ago] = 1 unless params[:days_ago].present?
      @report = params[:days_ago].to_i > 0 ? Artifacts::Image.distribution_by_admin_user(params[:days_ago].to_i) : Artifacts::Image.distribution_by_admin_user
      respond_to do |format|
        format.html
        format.js
      end
    end

    def get_coordinates
    end

    def set_rating
      Artifacts::Image.find(params[:image_id]).update_attributes!(:rating => params[:rating])
    end

    private

      def image_params
        params.require(:artifacts_image).permit(:tag_list, :special_tag_list, :client_id, :reusable, :city, :region1, :region2, :country, :use_for_landing_pages, :product_id, :rating, :categories, :industry_id)
      end
  end
end
