class Sandbox::VideoMarketingCampaignFormsController < Sandbox::BaseController
  include Requests
  skip_before_filter :authenticate_admin_user!, :only => [:new, :create, :edit, :update, :search, :stock_images, :stock_image_templates, :upload_client_images, :upload_license_file, :associate_license_to_images, :client_images_destroy, :content_landing]
  before_action :set_video_marketing_campaign_form, only: [:edit, :update, :stock_images, :stock_image_templates, :upload_client_images, :upload_license_file, :associate_license_to_images, :client_images_destroy, :content_landing]
	before_action :set_session_params, only:%w(new create edit update)
  DEALERS_DEFAULT_LIMIT = 100
	IMAGES_LIMIT = 24
	IMAGE_CATEGORIES = %w(people building trucks other)

  def landing
    params[:step] = 2
    @query_params = request.query_parameters
    @play_video = @query_params[:play_video] == "true"
    @video_marketing_campaign_form = if @video_marketing_campaign_form_public_profile_uuid.present? && @video_marketing_campaign_form_id.present?
      VideoMarketingCampaignForm.where(id: @video_marketing_campaign_form_id).first
    else
      nil
    end
  end

  def content_landing
    params[:step] = 4
    @video_marketing_campaign_form = if @video_marketing_campaign_form_public_profile_uuid.present? && @video_marketing_campaign_form_id.present?
      VideoMarketingCampaignForm.where(id: @video_marketing_campaign_form_id).first
    else
      nil
    end
  end

  def detect_other_dealers
    @video_marketing_campaign_form = nil
    dealers = []
    selected_dealers = params[:dealer_id].to_s.strip.present? ? Dealer.where(id: params[:dealer_id].split(",").map(&:to_i)) : []

    if selected_dealers.present? && (params[:phone].present? || params[:email].present? || params[:website].present?)
      column_names = Dealer.column_names
      column_names.delete('service_areas')
      column_names.delete('zipcode_list')
      column_names.delete('week_hours')
      column_names_string = "dealers." + column_names.join(",dealers.")

      or_conditions = []
      phones = []
      selected_dealers.each do |d|
        phones << d.target_phone.to_s.gsub(/[^a-zA-Z0-9]/, "").strip
        phones << d.phone1.to_s.gsub(/[^a-zA-Z0-9]/, "").strip
        phones << d.phone2.to_s.gsub(/[^a-zA-Z0-9]/, "").strip
        phones << d.phone3.to_s.gsub(/[^a-zA-Z0-9]/, "").strip
        phones << d.permalease_phone.to_s.gsub(/[^a-zA-Z0-9]/, "").strip
      end

      names = selected_dealers.map{|d| d.name.downcase.gsub('&', 'and').gsub(/,inc| incorporated| inc|&|[^a-zA-Z0-9]/, '').strip}
      phones = phones.compact.reject(&:blank?)
      emails = selected_dealers.map(&:email).map{|e| e.to_s.downcase.gsub(/[^a-zA-Z0-9]/, "").strip}.compact.reject(&:blank?)
      websites = selected_dealers.map(&:website).map{|w| w.to_s.downcase.gsub(/www|https|http/, "").gsub(/[^a-zA-Z0-9]/, "").strip}.compact.reject(&:blank?)

      if phones.present?
      or_conditions << "regexp_replace(dealers.target_phone, '[^a-zA-Z0-9]', '', 'g') IN ('#{phones.join('\', \'')}') OR regexp_replace(dealers.phone1, '[^a-zA-Z0-9]', '', 'g') IN ('#{phones.join('\', \'')}') OR regexp_replace(dealers.phone2, '[^a-zA-Z0-9]', '', 'g') IN ('#{phones.join('\', \'')}') OR regexp_replace(dealers.phone3, '[^a-zA-Z0-9]', '', 'g') IN ('#{phones.join('\', \'')}') OR regexp_replace(dealers.permalease_phone, '[^a-zA-Z0-9]', '', 'g') IN ('#{phones.join('\', \'')}')"
      end
      if emails.present?
        email_domains = selected_dealers.map(&:email).map{|e| e.to_s.downcase.strip.gsub(/[^a-zA-Z0-9@]/, "").split("@").second}.compact.reject(&:blank?) - %w(gmailcom yahoocom hotmailcom aolcom msncom yahoocoin livecom ymailcom)
        emails.each do |e|
          or_conditions << "regexp_replace(LOWER(dealers.email), '[^a-zA-Z0-9]', '', 'g') = '#{e}'"
        end
        if email_domains.present?
          or_conditions << "regexp_replace(regexp_replace(LOWER(dealers.email), '[^a-zA-Z0-9@]', '', 'g'), '^.*@+', '', 'g') IN ('#{email_domains.join('\', \'')}')"
          or_conditions << "regexp_replace(regexp_replace(LOWER(dealers.website), 'www|https|http', '', 'g'), '[^a-zA-Z0-9]', '', 'g') IN ('#{email_domains.join('\', \'')}')"
        end
      end
      if websites.present?
        or_conditions << "regexp_replace(regexp_replace(LOWER(dealers.website), 'www|https|http', '', 'g'), '[^a-zA-Z0-9]', '', 'g') IN ('#{websites.join('\', \'')}')"
        or_conditions << "regexp_replace(regexp_replace(LOWER(dealers.email), '[^a-zA-Z0-9@]', '', 'g'), '^.*@+', '', 'g') IN ('#{websites.join('\', \'')}')"
      end
      names.each do |n|
        or_conditions << "regexp_replace(
                          regexp_replace(
                            lower(dealers.name), '&', 'and', 'g'),
                          ',inc| incorporated| inc|&|[^a-zA-Z0-9]', '', 'g') LIKE '%#{n}%'"
      end

      if or_conditions.present?
        dealers = Dealer.unscoped.distinct.select("#{column_names_string}").joins("INNER JOIN jobs ON jobs.resource_id = dealers.id AND jobs.resource_type = 'Dealer'")
          .by_industry_id(params[:industry_id])
          .where(or_conditions.join(" OR "))
          .where("dealers.id not in (?)", selected_dealers.map(&:id))
          .order("dealers.name ASC")
          .page(params[:page]).per(params[:limit])
      end
    end
    query_params =  request.query_parameters
    render :detect_other_dealers, locals: {dealers: dealers, query_params: query_params}
  end

  def search
    @video_marketing_campaign_form = nil
    respond_to do |format|
      format.html {
        params[:step] = "0"
        @dealers = Dealer.where(id: -1).page(params[:page]).per(params[:limit])
      }
      format.js {
        params[:limit] = DEALERS_DEFAULT_LIMIT unless params[:limit].present?
        column_names = Dealer.column_names
        column_names.delete('service_areas')
        column_names.delete('zipcode_list')
        column_names.delete('week_hours')
        column_names_string = "dealers." + column_names.join(",dealers.")

    		@dealers = if params[:id].present?
          puts "BY ID"
          Dealer.unscoped.distinct.select("#{column_names_string}").joins("INNER JOIN jobs ON jobs.resource_id = dealers.id AND jobs.resource_type = 'Dealer'")
      			.by_id(params[:id])
            .by_industry_id(params[:industry_id])
            .order("dealers.name ASC")
      			.page(params[:page]).per(params[:limit])
        else
          dealers = []
          if params[:phone].present? || params[:email].present? || params[:website].present? || params[:zipcode].present?
            puts "BY PHONE OR EMAIL OR WEBSITE OR STRICT NAME"
            or_conditions = []
            phone = params[:phone].to_s.gsub(/[^a-zA-Z0-9]/, "").strip
            email = params[:email].to_s.downcase.gsub(/[^a-zA-Z0-9]/, "").strip
            website = params[:website].to_s.downcase.gsub(/www|https|http/, "").gsub(/[^a-zA-Z0-9]/, "").strip
            zipcode = params[:zipcode].to_s.strip.first(5)
            or_conditions << "regexp_replace(dealers.target_phone, '[^a-zA-Z0-9]', '', 'g') = '#{phone}' OR regexp_replace(dealers.phone1, '[^a-zA-Z0-9]', '', 'g') = '#{phone}' OR regexp_replace(dealers.phone2, '[^a-zA-Z0-9]', '', 'g') = '#{phone}' OR regexp_replace(dealers.phone3, '[^a-zA-Z0-9]', '', 'g') = '#{phone}' OR regexp_replace(dealers.permalease_phone, '[^a-zA-Z0-9]', '', 'g') = '#{phone}'" if phone.present?
            if email.present?
              or_conditions << "regexp_replace(LOWER(dealers.email), '[^a-zA-Z0-9]', '', 'g') = '#{email}'"
              email_domain = params[:email].to_s.downcase.strip.gsub(/[^a-zA-Z0-9@]/, "").split("@").second
              or_conditions << "regexp_replace(regexp_replace(LOWER(dealers.website), 'www|https|http', '', 'g'), '[^a-zA-Z0-9]', '', 'g') = '#{email_domain}'" if email_domain.present? && !%w(gmailcom yahoocom hotmailcom aolcom msncom yahoocoin livecom ymailcom).include?(email_domain)
            end
            if website.present?
              or_conditions << "regexp_replace(regexp_replace(LOWER(dealers.website), 'www|https|http', '', 'g'), '[^a-zA-Z0-9]', '', 'g') = '#{website}'"
              or_conditions << "regexp_replace(regexp_replace(LOWER(dealers.email), '[^a-zA-Z0-9@]', '', 'g'), '^.*@+', '', 'g') = '#{website}'"
            end
            # name = "#{params[:name].downcase.gsub('&', 'and').gsub(/,inc| incorporated| inc|&|[^a-zA-Z0-9]/, '').gsub("airconditioning", 'ac').gsub('airconditioing', 'ac').strip}"
            # or_conditions << "regexp_replace(
            #                 regexp_replace(
            #                   regexp_replace(
            #                     regexp_replace(
            #                       lower(dealers.name), '&', 'and', 'g'),
            #                     ',inc| incorporated| inc|&|[^a-zA-Z0-9]', '', 'g'),
            #                 'airconditioning', 'ac', 'g'),
            #               'airconditioing', 'ac', 'g') = '#{name}'"

            if or_conditions.present?
              dealers = Dealer.unscoped.distinct.select("#{column_names_string}").joins("INNER JOIN jobs ON jobs.resource_id = dealers.id AND jobs.resource_type = 'Dealer'")
                .by_industry_id(params[:industry_id])
                .where(or_conditions.join(" OR "))
                .by_zipcode(zipcode)
                .order("dealers.name ASC")
          			.page(params[:page]).per(params[:limit])

              if !dealers.present?
                puts "NOT FOUND, USE WIHOUT ZIPCODE"
                dealers = Dealer.unscoped.distinct.select("#{column_names_string}").joins("INNER JOIN jobs ON jobs.resource_id = dealers.id AND jobs.resource_type = 'Dealer'")
                  .by_industry_id(params[:industry_id])
                  .where(or_conditions.join(" OR "))
                  .order("dealers.name ASC")
            			.page(params[:page]).per(params[:limit])

                if dealers.present?
                  names = dealers.map{|d| d.name.downcase.gsub('&', 'and').gsub(/,inc| incorporated| inc|&|[^a-zA-Z0-9]/, '').gsub("airconditioning", 'ac').gsub('airconditioing', 'ac').strip}
                  or_conditions << "regexp_replace(
                                  regexp_replace(
                                    regexp_replace(
                                      regexp_replace(
                                        lower(dealers.name), '&', 'and', 'g'),
                                      ',inc| incorporated| inc|&|[^a-zA-Z0-9]', '', 'g'),
                                  'airconditioning', 'ac', 'g'),
                                'airconditioing', 'ac', 'g') in (#{names.map{|e| '\'' + e + '\''}.join(',')})"

                  dealers = Dealer.unscoped.distinct.select("#{column_names_string}").joins("INNER JOIN jobs ON jobs.resource_id = dealers.id AND jobs.resource_type = 'Dealer'")
                    .by_industry_id(params[:industry_id])
                    .where(or_conditions.join(" OR "))
                    .order("dealers.name ASC")
                    .page(params[:page]).per(params[:limit])
                end
              end
            end
          end

          if params[:name].present? && !dealers.present?
            puts "BY NAME"
            or_conditions = []
            # if zipcode.present?
            #   or_conditions << "LEFT(dealers.zipcode, 5) = '#{zipcode}'"
            #   or_conditions << "dealers.zipcode_list LIKE '%#{zipcode}%'"
            # end
            dealers = Dealer.unscoped.distinct.select("#{column_names_string}").joins("INNER JOIN jobs ON jobs.resource_id = dealers.id AND jobs.resource_type = 'Dealer'").by_name(params[:name])
            .by_industry_id(params[:industry_id])
            .order("dealers.name ASC").page(params[:page]).per(params[:limit])
          end
          dealers
        end
        render :search, locals: {dealers: @dealers}
      }
    end
  end

  def new
    @cities_json = []
    zipcode = params[:zipcode].to_s.strip
    phones = [params[:phone].to_s.strip].compact.reject(&:empty?).uniq
    phones.each_with_index do |phone, index|
      phones[index] = "f:#{phone.to_s.gsub(/[^\d]/, '')}"
    end
    primary_phone = phones.first
    phones.shift
    @video_marketing_campaign_form = VideoMarketingCampaignForm.new(company_name: params[:name].to_s.strip, company_email: params[:email].to_s.strip, website: params[:website].to_s.strip, primary_phone: primary_phone, zipcode: zipcode, company_phones: phones, country: Geobase::Country.find_by_code("US").try(:name), industry_id: params[:industry_id].try(&:to_i), is_email_registration: params[:is_email_registration])
    dealer_ids = params[:dealer_id].to_s.split(",").map(&:to_i)
    dealers = Dealer.where(id: dealer_ids)
    dealer = Dealer.where(id: dealer_ids.first).first
    @client_aae_template_types = %w(introduction call_to_action ending transition general bridge_to_subject collage credits subscription)
    @project_type = params[:project_type] || @client_aae_template_types.first
    if dealer.present?
      phones = [dealer.target_phone, dealers.map(&:target_phone), dealers.map(&:phone1), dealers.map(&:phone2), dealers.map(&:phone3), dealers.map(&:permalease_phone), params[:phone].to_s.strip].flatten.compact.reject(&:empty?).uniq
      primary_phone = phones.first
      phones.shift
      phones.each_with_index do |phone, index|
        phones[index] = "f:#{phone.to_s.gsub(/[^\d]/, '')}"
      end
      contact_person = dealer.contact_people.first
      brand_names = [dealers.map(&:brand_id), dealer.other_brands.to_s.split(",").map(&:strip)].flatten.compact.reject(&:empty?)
      primary_manufacturer = Client.distinct.where("business_type = ? AND lower(name) = ?", Client.business_type.find_value(:manufacturer).value, dealer.brand_id.to_s.downcase).first
      found_manufacturers = Client.distinct.where("business_type = ? AND lower(name) in (?)", Client.business_type.find_value(:manufacturer).value, brand_names.map(&:downcase))
      brands = found_manufacturers.map(&:id).map(&:to_s) - [primary_manufacturer.try(:id).to_s]
      other_brands = (brand_names - found_manufacturers.map(&:name)).compact.reject(&:empty?).uniq.join("; ")
      main_email = [dealer.email, dealers.map(&:email)].flatten.compact.reject(&:blank?).first.to_s.downcase
      main_website = [dealer.website, dealers.map(&:website)].flatten.compact.reject(&:blank?).first.to_s.downcase
      @video_marketing_campaign_form = VideoMarketingCampaignForm.new(primary_brand: primary_manufacturer.try(:id), industry_id: params[:industry_id].try(&:to_i) || dealer.try(:industry_id), dealer_ids: dealer_ids.map(&:to_i).to_s.delete(' ').gsub("[", "{").gsub("]", "}"), country: Geobase::Country.find_by_code("US").try(:name), company_name: dealer.name, company_nickname: dealer.name, company_email: main_email.present? ? main_email.downcase : params[:email].to_s.downcase.strip, address1: dealer.address_line1, address2: dealer.address_line2, zipcode: zipcode.present? ? zipcode : dealer.zipcode, locality: dealer.city, region: dealer.state, company_phones: phones, website: main_website.present? ? main_website : params[:website].to_s.strip, facebook_url: dealer.facebook_url, twitter_url: dealer.twitter_url, google_plus_url: dealer.google_plus_url, youtube_url: dealer.youtube_url, brands: brands, other_brands: other_brands, contact_first_name: contact_person.try(:first_name), contact_last_name: contact_person.try(:last_name), contact_email: contact_person.try(:email), contact_phones: contact_person.try(:phones), cities: dealer.cities, distributor_names_csv: dealers.map{|e| e.district.to_s.gsub(',', '')}.compact.reject(&:blank?).join(","), primary_phone: primary_phone, is_email_registration: params[:is_email_registration])
      %w(website facebook_url twitter_url google_plus_url youtube_url).each do |social_url|
        @video_marketing_campaign_form[social_url] = dealer[social_url][/^https?/] ? dealer[social_url] : "http://#{dealer[social_url].downcase.gsub('http://', '')}" if dealer[social_url].present?
      end
      # wordings = []
      # dealer.wordings.each do |wording|
      #   wordings << Wording.new(name: wording.name, source: wording.source)
      # end
      # @video_marketing_campaign_form.wordings = wordings
    end
  end

  def edit
    cookies.permanent[:video_marketing_campaign_form_public_profile_uuid] = @video_marketing_campaign_form.client.public_profile_uuid
    cookies.permanent[:video_marketing_campaign_form_id] = @video_marketing_campaign_form.id
    params[:step] = "2" unless params[:step].present?
    params[:client_images_limit] = 24 unless params[:client_images_limit].present?
    @uploaded_images = Social::Image.where(client_id: @video_marketing_campaign_form.client_id).order(created_at: :desc).page(params[:client_images_page]).per(params[:client_images_limit])

		# content step
		if params[:step].to_i == 4
			@stock_images_counts_by_categories = stock_images_counts_by_categories
			@stock_images_total_count = stock_images_scope.count
			@image_categories = IMAGE_CATEGORIES
			@stock_image_templates_total_count = stock_image_templates_scope.count
			@stock_image_templates_counts_by_categories = stock_image_templates_counts_by_categories
		end

    respond_to do |format|
      format.html {}
      format.js {
        render :edit, locals: {uploaded_images: @uploaded_images}
      }
    end

    # if params[:step] == "4"
    #   params[:stock_images_limit] = 24 unless params[:stock_images_limit].present?
    #   @stock_images = @video_marketing_campaign_form.industry_id.present? ? Artifacts::Image.where("industry_id = ? AND file_file_name IS NOT NULL AND file_file_size IS NOT NULL", @video_marketing_campaign_form.industry_id).tagged_with("stock").tagged_with(%w(people building trucks other), any: true).order(created_at: :asc).page(params[:stock_images_page]).per(params[:stock_images_limit]) : Artifacts::Image.where(id: -1).page(params[:stock_images_page]).per(params[:stock_images_limit])
    # end
  end

  def create
    @video_marketing_campaign_form = VideoMarketingCampaignForm.new(video_marketing_campaign_form_params)
    @video_marketing_campaign_form.detect_other_localities
    cities = @video_marketing_campaign_form.cities.present? ? Geobase::Locality.joins("LEFT OUTER JOIN geobase_regions ON geobase_regions.id = geobase_localities.primary_region_id").where("geobase_localities.id in (#{@video_marketing_campaign_form.cities.to_s.gsub(/(\[|\])|"/, '')})").order("geobase_regions.name ASC, geobase_localities.name ASC") : []
    @cities_json = cities.map { |e| {id: e.id, text: "#{e.name}, #{e.try(:primary_region).try(:code).try(:split, '<sep/>').try(:first).to_s.gsub('US-', '')}"} }
    @video_marketing_campaign_form.ip_address = remote_ip_address
    @video_marketing_campaign_form.user_agent = request.user_agent
    @client_aae_template_types = %w(introduction call_to_action ending transition general bridge_to_subject collage credits subscription)
    @project_type = params[:project_type] || @client_aae_template_types.first

    respond_to do |format|
      if @video_marketing_campaign_form.save
        cookies.permanent[:video_marketing_campaign_form_public_profile_uuid] = @video_marketing_campaign_form.client.public_profile_uuid
        cookies.permanent[:video_marketing_campaign_form_id] = @video_marketing_campaign_form.id
        receivers = Setting.get_value_by_name("VideoMarketingCampaignForm::EMAIL_RECEIVERS")
        subject = "Video Marketing Campaign Form - New Client Signup"
        body = "New video marketing campaign form submit at #{Time.now} with id ##{@video_marketing_campaign_form.id}, please review at #{Rails.configuration.routes_default_url_options[:host]}#{Rails.application.routes.url_helpers.edit_sandbox_video_marketing_campaign_form_path(@video_marketing_campaign_form.id, public_profile_uuid: @video_marketing_campaign_form.client.public_profile_uuid)}"
        BroadcasterMailer.delay(queue: DelayedJobQueue::OTHER, priority: DelayedJobPriority::HIGH).custom_mail(receivers, subject, body) if receivers.present?
        Utils.pushbullet_broadcast(subject, body) if Rails.env.production?
        format.html { redirect_to edit_sandbox_video_marketing_campaign_form_path(@video_marketing_campaign_form, step: "3", public_profile_uuid: @video_marketing_campaign_form.client.public_profile_uuid), notice: "Step was successfully submitted!" }
      else
        format.html { render action: 'new' }
      end
    end
  end

  def update
    respond_to do |format|
			if @video_marketing_campaign_form.update(video_marketing_campaign_form_params)
        next_step = 2
        next_step = params[:step].to_i + 1 if params[:step].present? && params[:step].to_i < 4
        if params[:step].to_i == 4
          format.html { redirect_to edit_sandbox_video_marketing_campaign_form_path(@video_marketing_campaign_form, step: 4, public_profile_uuid: params[:public_profile_uuid]), notice: "Step was successfully submitted!" }
        elsif params[:step].to_i == 3
          format.html { redirect_to content_landing_sandbox_video_marketing_campaign_form_path(@video_marketing_campaign_form, public_profile_uuid: params[:public_profile_uuid]), notice: "Step was successfully submitted!" }
        else
  				format.html { redirect_to edit_sandbox_video_marketing_campaign_form_path(@video_marketing_campaign_form, step: next_step, public_profile_uuid: params[:public_profile_uuid]), notice: "Step was successfully submitted!" }
        end
			else
        cities = @video_marketing_campaign_form.cities.present? ? Geobase::Locality.joins("LEFT OUTER JOIN geobase_regions ON geobase_regions.id = geobase_localities.primary_region_id").where("geobase_localities.id in (#{@video_marketing_campaign_form.cities.to_s.gsub(/(\[|\])|"/, '')})").order("geobase_regions.name ASC, geobase_localities.name ASC") : []
        @cities_json = cities.map { |e| {id: e.id, text: "#{e.name}, #{e.try(:primary_region).try(:code).try(:split, '<sep/>').try(:first).to_s.gsub('US-', '')}", population: e.population.to_i.to_s(:delimited)} }
        @uploaded_images = Social::Image.where(client_id: @video_marketing_campaign_form.client_id).order(created_at: :desc).page(params[:client_images_page]).per(params[:client_images_limit])
				format.html { render action: 'edit', public_profile_uuid: @video_marketing_campaign_form.client.public_profile_uuid }
			end
		end
  end

  def stock_images
    @stock_images = stock_images_scope(params[:category]).
			order(created_at: :asc).
			page(params[:stock_images_page]).
			per(IMAGES_LIMIT)
    respond_to do |format|
      format.html {}
      format.js {
        render :stock_images, locals: {stock_images: @stock_images}
      }
    end
  end

	def stock_image_templates
    @stock_image_templates = stock_image_templates_scope(params[:category]).
			where(is_active:true).
			order(created_at: :asc).
			page(params[:stock_image_templates_page]).
			per(IMAGES_LIMIT)
    respond_to do |format|
      format.html {}
      format.js {
        render :stock_image_templates, locals: {stock_image_templates: @stock_image_templates}
      }
    end
  end

  def upload_client_images
    @image = Social::Image.new
    @image.file = params[:video_marketing_campaign_form][:file].first
    file_name = @image.try(:file_file_name).to_s
    @image.title = File.basename(file_name).gsub(File.extname(file_name),'').to_s.humanize
    @image.client_id = params[:video_marketing_campaign_form][:client_id]

    respond_to do |format|
      if @image.save
        format.json{render json: {files: [@image.to_json_format]}, status: :created}
      else
        format.json{ render json: @image.errors, status: :unprocessable_entity}
      end
    end
  end

  def upload_license_file
    @license = LicenseProof.new(:file => params[:video_marketing_campaign_form][:license_proof_file].first)
    respond_to do |format|
      if @license.save
        format.json{render json: {files: [@license.to_json_format]}, status: :created}
      else
        format.json{ render json: @license.errors, status: :unprocessable_entity}
      end
    end
  end

  def associate_license_to_images
    @client_images = Social::Image.where(id: params[:uploaded_images_ids], license_proof_id: nil)
    @client_images.each do |item|
      item.update_attributes(:license_proof_id => params[:license_proof_file_id])
    end
  end

  def client_images_destroy
    Social::Image.find(params[:image_id]).destroy unless params[:image_id].blank?
    params[:client_images_limit] = 24 unless params[:client_images_limit].present?
    @uploaded_images = Social::Image.where(client_id: @video_marketing_campaign_form.client_id).order(created_at: :desc).page(params[:client_images_page]).per(params[:client_images_limit])
  end

	def youtube_oauth_callback
    vmcf = unset_youtube_package_vmcf_fields(VideoMarketingCampaignForm.find(session[:vmcf_id]))

		vmcf.youtube_refresh_token = YoutubeApiService.get_refresh_token(params[:code])

		youtube_channel_info = YoutubeApiService.get_youtube_channel_info(vmcf.youtube_refresh_token)
		vmcf.youtube_channel_id = youtube_channel_info[:id]
		vmcf.youtube_channel_url = youtube_channel_info[:url]
		vmcf.youtube_channel_profile_image_url = youtube_channel_info[:avatar_url]
		vmcf.youtube_channel_title = youtube_channel_info[:title]

		google_account_info = YoutubeApiService.get_google_account_info(vmcf.youtube_refresh_token)
		vmcf.google_account_first_name = google_account_info[:first_name]
		vmcf.google_account_last_name = google_account_info[:last_name]
		vmcf.google_account_email = google_account_info[:email]
		vmcf.google_plus_profile_url = google_account_info[:google_plus_profile_url]
		vmcf.google_plus_profile_image_url = google_account_info[:google_plus_profile_image_url]

    vmcf.save!(validate: false)
    respond_to do |format|
      format.html { redirect_to edit_sandbox_video_marketing_campaign_form_path(vmcf, step: "3", public_profile_uuid: vmcf.client.public_profile_uuid, section:'youtube_channel'), notice: "Refresh Token was successfully obtained" }
    end
  end

  def youtube_channel_section
    @video_marketing_campaign_form = VideoMarketingCampaignForm.find(params[:id])
    respond_to do |format|
      format.js{}
    end
  end

	def unbind_youtube_channel
		vmcf = unset_youtube_package_vmcf_fields(VideoMarketingCampaignForm.find(params[:id]))
		vmcf.save!(validate: false)
	end

  private
    def set_video_marketing_campaign_form
      @client_aae_template_types = %w(introduction call_to_action ending transition general bridge_to_subject collage credits subscription)
    	@project_type = params[:project_type] || @client_aae_template_types.first
      if %w(edit update).include?(params[:action])
        Client.find_by_public_profile_uuid!(params[:public_profile_uuid])
      end
      @video_marketing_campaign_form = VideoMarketingCampaignForm.find(params[:id])
      cities = @video_marketing_campaign_form.cities.present? ? Geobase::Locality.joins("LEFT OUTER JOIN geobase_regions ON geobase_regions.id = geobase_localities.primary_region_id").where("geobase_localities.id in (#{@video_marketing_campaign_form.cities.to_s.gsub(/(\[|\])|"/, '')})").order("geobase_regions.name ASC, geobase_localities.name ASC") : []
      @cities_json = cities.map { |e| {id: e.id, text: "#{e.name}, #{e.try(:primary_region).try(:code).try(:split, '<sep/>').try(:first).to_s.gsub('US-', '')}", population: e.population.to_i.to_s(:delimited)} }
    end
		# Never trust parameters from the scary internet, only allow the white list through.
		def video_marketing_campaign_form_params
      params[:video_marketing_campaign_form] = params[:video_marketing_campaign_form].to_h unless params[:video_marketing_campaign_form].present?
      brands = params[:video_marketing_campaign_form][:brands].to_a.uniq
      brands.delete("0")
      params[:video_marketing_campaign_form][:brands] = brands
      params[:video_marketing_campaign_form][:tag_list] = sanitize_tags(params[:video_marketing_campaign_form][:tag_list])
      #params[:video_marketing_campaign_form][:dealer_ids] = params[:video_marketing_campaign_form][:dealer_ids].to_s.delete(' ') if params[:video_marketing_campaign_form][:dealer_ids].present?
			params.require(:video_marketing_campaign_form).permit!
		end

    def sanitize_tags(tags)
      tags.to_s.split(',').reject(&:blank?).map{|e|e.to_s.mb_chars.downcase.to_s}.uniq
    end

		def set_session_params
      session[:vmcf_id] = @video_marketing_campaign_form.try(:id)
    end

		def unset_youtube_package_vmcf_fields(vmcf)
			['youtube_refresh_token',
				'youtube_channel_id',
				'youtube_channel_url',
				'youtube_channel_title',
				'youtube_channel_profile_image_url',
				'google_account_email',
				'google_account_first_name',
				'google_account_last_name',
				'google_plus_profile_url',
				'google_plus_profile_image_url'
			].each do |f|
				vmcf.send("#{f}=".to_sym, nil)
			end
			vmcf
		end

		def stock_images_scope(category = nil)
			categories = (category.present? && IMAGE_CATEGORIES.include?(category)) ? category : IMAGE_CATEGORIES
			return Artifacts::Image.
				where("industry_id = ? AND file_file_name IS NOT NULL AND file_file_size IS NOT NULL", @video_marketing_campaign_form.industry_id).
				tagged_with("stock").
				tagged_with(categories, any: true)
		end

		def stock_images_counts_by_categories
			res = {}
			IMAGE_CATEGORIES.each do |c|
				res[c] = stock_images_scope(c).count
			end
			return res
		end

		def stock_image_templates_scope(category = nil)
			available_categories = Templates::StockImageTemplate::CATEGORIES.stringify_keys.keys
			scope = Templates::StockImageTemplate.where(is_active: true)
			scope = scope.with_category(category) if category.present? && available_categories.include?(category)
			return scope
		end

		def stock_image_templates_counts_by_categories
			res = {}
			Templates::StockImageTemplate::CATEGORIES.stringify_keys.keys.to_a.each do |c|
				res[c] = stock_image_templates_scope(c).count
			end
			return res
		end
end
