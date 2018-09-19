class DealersController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:save]
  before_action :set_dealer, only: [:edit, :update, :show, :destroy, :add_similar, :send_invitation]
	DEALERS_DEFAULT_LIMIT = 25

  def save
    response = if request.body.present?
      json = JSON.load(request.body.read)
      ActiveRecord::Base.logger.info "DEALERJSON: #{json}"
      if json.present? && json["name"].present? && json["brand_id"].present?
        json["name"] = json["name"].gsub("&amp;", " & ").squeeze(" ").strip
        json["client_id"] = Client.find_by_name(json["brand_id"].strip).try(:id)
        json["country"] = "US"
        if json["address_line1"].present?
          if ["Husqvarna"].include?(json["brand_id"])
            json["client_id"] = Client.find_by_name("Husqvarna").try(:id)
            address = json["address_line1"].to_s.strip.split(',').map(&:strip)
            json["address_line1"] = json["address_line1"].gsub(", #{address.last}", "")
            json["address_line2"] = address.last.strip
            state_code = address.last.to_s.split(" ").first.strip
            zipcode = address.last.to_s.split(" ").last.first(5)
            state = Geobase::Region.where("code like ? AND level = 1", "US-#{state_code}%").first.try(:name)
            json["zipcode"] = zipcode
            json["state"] = state
            json["country"] = "US"
            if zipcode.present?
              cities = []
              localities = []
              if zipcode.present?
                geo_zip = Geobase::ZipCode.find_by_code(zipcode)
                if geo_zip.present? && geo_zip.localities.map(&:id).present?
                  default_country_id = Geobase::Country.find_by_code("US").id
                  localities = Geobase::Locality.joins("LEFT JOIN geobase_regions ON geobase_regions.id = geobase_localities.primary_region_id").where("geobase_localities.id in (?) AND geobase_regions.country_id = ?", geo_zip.localities.map(&:id), default_country_id).order("geobase_localities.population DESC NULLS LAST")
                end
              end
              json["city"] = localities.first.try(:name)
              cities = localities.map(&:id).map(&:to_s)
              cities.flatten!
              cities.uniq!
              json["cities"] = cities
            end
            json["industry_id"] = 994
          end
        end
        if json["address_line2"].present?
          if ["Mitsubishi", "Daikin", "Carrier", "Kubota", "Mahindra"].include?(json["brand_id"])
            json["zipcode"] = json['address_line2'].split(' ').last.strip
            json["city"] = json['address_line2'].split(',').first.strip.titleize
            state_name_or_code = json['address_line2'].split(',').last.strip.gsub(json['zipcode'], '').strip
            json["state"] = Geobase::Region.where("(code like ? OR name = ?) AND level = 1", "US-#{state_name_or_code}%", state_name_or_code).first.try(:name)
          end
          if ["Heil", "Day & Night", "New Holland"].include?(json["brand_id"])
            address_line2 = json['address_line2'].split(",")
            json["zipcode"] = address_line2.last.to_s.strip
            json["city"] = address_line2.first.to_s.strip.titleize
            state_name_or_code = address_line2.second.to_s.strip
            json["state"] = Geobase::Region.where("(code like ? OR name = ?) AND level = 1", "US-#{state_name_or_code}%", state_name_or_code).first.try(:name)
          end
          if ["John Deere"].include?(json["brand_id"])
            address_line2 = json['address_line2'].to_s.split(" ")
            json["zipcode"] = address_line2[-1].to_s.strip
            state_name_or_code = address_line2[-2].to_s.strip
            json["city"] = json['address_line2'].to_s.gsub("#{state_name_or_code} #{json['zipcode']}", "").strip
            json["state"] = Geobase::Region.where("(code like ? OR name = ?) AND level = 1", "US-#{state_name_or_code}%", state_name_or_code).first.try(:name)
          end
          if ["McCormick"].include?(json["brand_id"])
            address_line2 = json['address_line2'].to_s.strip.split(" ")
            json["zipcode"] = address_line2[0].to_s.strip
            state_code = address_line2[-1].to_s.gsub("(", "").gsub(")", "").strip
            json["city"] = json['address_line2'].to_s.gsub("#{json['zipcode']}", "").gsub(" #{address_line2[-1].to_s.strip}", "").strip
            json["state"] = Geobase::Region.where("code like ? AND level = 1", "US-#{state_code}%").first.try(:name)
          end
          if ["Simplicity"].include?(json["brand_id"])
            code = json['address_line2'].split(',').last.split(' ').first.strip
            zip = json['address_line2'].split(',').last.strip.gsub("#{code} ", '').strip
            region = Geobase::Region.where("(temp_code = ? OR code LIKE ?) AND level = 1", code, "%-#{code}%").first
            json["zipcode"] = region.try(:country).try(:code) == "US" ? zip.first(5) : zip
            json["city"] = json['address_line2'].split(',').first.strip
            json["state"] = region.try(:name)
            json["country"] = region.try(:country).try(:code)
            zipcode = json["zipcode"]
            if zipcode.present?
              cities = []
              localities = []
              if zipcode.present? && region.present?
                if region.try(:country).try(:code) == "CA"
                  if zipcode.size == 6
                    zipcode = zipcode.insert(3, " ")
                  end
                end
                geo_zip = Geobase::ZipCode.find_by_code(zipcode)
                if geo_zip.present? && geo_zip.localities.map(&:id).present?
                  localities = Geobase::Locality.joins("LEFT JOIN geobase_regions ON geobase_regions.id = geobase_localities.primary_region_id").where("geobase_localities.id in (?) AND geobase_regions.country_id = ?", geo_zip.localities.map(&:id), region.try(:country_id)).order("geobase_localities.population DESC NULLS LAST")
                end
              end
              cities = localities.map(&:id).map(&:to_s)
              cities.flatten!
              cities.uniq!
              json["cities"] = cities
            end
            json["industry_id"] = 994
          end
        end
        ActiveRecord::Base.transaction do
          similar_records = Dealer.where("LOWER(name) = ? AND brand_id = ?", json["name"].downcase, json["brand_id"].strip)
          dealer = Dealer.where(name: similar_records.size == 0 ? json["name"] : similar_records.first.name, brand_id: json["brand_id"].strip).first_or_initialize
          cities = dealer.cities.to_a
          phone_old = nil
          if json["target_phone"].present? && dealer.target_phone.present? && dealer.target_phone != json["target_phone"]
            phone_old = dealer.target_phone
          end
          dealer.attributes = json
          dealer.cities = (cities + json["cities"].to_a).compact.reject(&:blank?).uniq
          if phone_old.present?
            if !dealer.phone2.present?
              dealer.phone2 = phone_old
            elsif !dealer.phone3.present?
              dealer.phone3 = phone_old
            end
          end
          dealer.save
        end
        {status: 200}
      else
        {status: 500}
      end
    else
      {status: 500}
    end
    render json: response
  end

	def index
		params[:limit] = DEALERS_DEFAULT_LIMIT unless params[:limit].present?

		if params[:filter].present?
			params[:filter][:order] = 'created_at' unless params[:filter][:order].present?
			params[:filter][:order_type] = 'asc' unless params[:filter][:order_type].present?
		else
			params[:filter] = { order: 'updated_at', order_type: 'desc' }
		end

		order_by = 'dealers.' + params[:filter][:order]
    column_names = Dealer.column_names
    column_names.delete('service_areas')
    column_names.delete('zipcode_list')
    column_names.delete('week_hours')
    column_names_string = "dealers." + column_names.join(",dealers.")
    join_string = [params[:dealer_check_queue_status].present?, params[:dealer_check_queue_admin_user_id].present?, params[:dealer_check_queue_days_ago].present?].any? ? "LEFT OUTER JOIN jobs ON jobs.resource_id = dealers.id AND jobs.resource_type = 'Dealer'" : ""
		@dealers = Dealer.unscoped.distinct.select("#{column_names_string}, #{order_by}").joins(join_string)
			.by_id(params[:id])
      .by_name(params[:name])
      .by_brand_id(params[:brand_id])
      .by_state(params[:state])
      .by_dealer_check_queue_status(params[:dealer_check_queue_status])
      .by_dealer_check_queue_admin_user_id(params[:dealer_check_queue_admin_user_id])
      .by_dealer_check_queue_days_ago(params[:dealer_check_queue_days_ago])
			.page(params[:page]).per(params[:limit])
			.order(order_by + ' ' + params[:filter][:order_type])
	end

	def new
		@dealer = Dealer.new
    render :edit, locals: {dealer: @dealer}
	end

  def edit
    unless @dealer.other_brands.present?
      other_manufacturers = @dealer.get_matched_records.pluck(:brand_id).uniq.sort - [@dealer.brand_id]
      if other_manufacturers.present?
        @dealer.other_brands = other_manufacturers.join(", ")
      end
    end
    render :edit, locals: {dealer: @dealer, queue: params[:queue]}
  end

  def update
    if @dealer.update_attributes(dealer_params)
      if params[:queue] == "true"
        render :show, locals: {dealer: @dealer}
      else
        render :update, locals: {dealer: @dealer}
      end
    else
      render :edit, locals: {dealer: @dealer}
    end
  end

	def create
		@dealer = Dealer.new(dealer_params)
    if @dealer.save
      render :create, locals: {dealer: @dealer}
    else
      render :new, locals: {dealer: @dealer}
    end
	end

	def destroy
		@dealer.destroy
    render :destroy, locals: {dealer: @dealer}
	end

  def add_similar
    @dealer_id = params[:dealer_id].to_s
    if @dealer_id.present?
      if params[:is_duplicate].to_s == "true"
        @dealer.similar_dealers = (@dealer.similar_dealers.to_a + [@dealer_id]).compact.reject(&:blank?).uniq
      else
        @dealer.not_similar_dealers = (@dealer.not_similar_dealers.to_a + [@dealer_id]).compact.reject(&:blank?).uniq
      end
      @dealer.save(validate: false)
    end
  end

  def send_invitation
    EchoMailer.dealer_first_email(@dealer.email, @dealer, current_admin_user)
    render :send_invitation, locals: {dealer: @dealer}
  end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_dealer
			@dealer = Dealer.find(params[:id])
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def dealer_params
			params.require(:dealer).permit!
		end
end
