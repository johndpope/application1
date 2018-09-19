class ClientsController < ApplicationController
  include ClientAssets
  before_action :set_client, only: [:show, :edit, :update, :destroy, :aae_templates, :subject_videos, :donor_videos,
    :general_image_tags, :source_video_image_tags, :update_general_image_tags, :update_source_video_image_tags, :assign_accounts_to_bot_server, :legend, :assets, :assets_images]
  before_action :get_assets, only: [:assets]

  DEFAULT_LIMIT = 25
  IMAGES_COUNT_DEFAULT_LIMIT = 50

  # GET /clients
  # GET /clients.json
  def index
    params[:limit] = DEFAULT_LIMIT unless params[:limit].present?
    params[:visible] = true unless params[:visible].present?
    if params[:filter].present?
      params[:filter][:order] = 'is_active' unless params[:filter][:order].present?
      params[:filter][:order_type] = 'desc' unless params[:filter][:order_type].present?
    else
      params[:filter] = { order: 'is_active', order_type: 'desc' }
    end

    order_by =
    if params[:filter][:order] == 'industry'
      "industries.name #{params[:filter][:order_type]}"
    else
      unless ['id', 'is_active', 'created_at'].include?(params[:filter][:order])
        "case
          when clients.#{params[:filter][:order]} IS NOT NULL AND clients.#{params[:filter][:order]} <> ''
            then 1
          else null
          end,
          clients.#{params[:filter][:order]} #{params[:filter][:order_type]}"
      else
        "clients.#{params[:filter][:order]} #{params[:filter][:order_type]}"
      end
    end
    column_names = Client.column_names
    column_names_string = "clients." + column_names.join(",clients.")
    @clients = Client.distinct.select("#{column_names_string}, #{order_by.chomp(params[:filter][:order_type])} as filter_column").joins("LEFT OUTER JOIN industries ON industries.id = clients.industry_id
    LEFT OUTER JOIN client_landing_pages ON clients.id = client_landing_pages.client_id
    LEFT OUTER JOIN email_accounts ON clients.id = email_accounts.client_id")
    .by_id(params[:id])
    .by_name(params[:name])
    .by_email(params[:email])
    .by_industry_id(params[:industry_id])
    .by_zipcode(params[:zipcode])
    .by_locality(params[:locality])
    .by_region(params[:region])
    .by_country(params[:country])
    .by_has_assets(params[:has_assets])
    .by_is_active(params[:is_active])
    .by_visible(params[:visible])
    .order("#{order_by} NULLS LAST, clients.name ASC")
    .page(params[:page]).per(params[:limit])
  end

  # GET /clients/1
  # GET /clients/1.json
  def show
  end

  # GET /clients/new
  def new
    @client = Client.new(is_active: true, industry_id: params[:industry_id])
    @clients = Client.all
  end

  # GET /clients/1/edit
  def edit
    @clients = Client.where("id <> ?", @client.id)
  end

  def tooltip_edit
    @tooltip = Tooltip.find(params[:id])
  end

  def tooltip_update
    @tooltip = Tooltip.find(params[:id])
    @tooltip.update_attributes(:value => params[:tooltip_text])
  end

  # POST /clients
  # POST /clients.json
  def create
    @client = Client.new(client_params)
    @client.name = @client.name.to_s.strip
    respond_to do |format|
      if @client.save
				#TODO: refactor
				ActiveRecord::Base.transaction do
					Product.where(id: params[:donor_client_products]).pluck(:client_id).uniq.each do |donor_client_id|
						ClientDonor.create! client_id: @client.id, donor_id: donor_client_id
					end

					params[:donor_client_products].to_a.each do |donor_client_product_id|
						donor_client_product = Product.find(donor_client_product_id)
						name = "#{@client.name} (#{donor_client_product.name})"
						@client.products.create! parent_id: donor_client_product_id, name: name, tag_list: [name], subject_title_components: donor_client_product.subject_title_components
					end
				end
        format.html { redirect_to (params[:donor_client_products].to_a.any? ? client_products_path(@client.id) : new_client_product_path(client_id: @client.id)), notice: 'Client was successfully created.' }
        response = { status: 200 }
        format.json { render json: response, status: response[:status] }
      else
        @clients = Client.all
        format.html { render action: 'new' }
        format.json { render json: @client.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /clients/1
  # PATCH/PUT /clients/1.json
  def update
		params[:client][:donor_video_ids] ||= [] unless params[:is_client_donor_videos_section].blank?
		params[:client][:certifying_manufacturer_ids] ||= [] unless params[:is_client_general_section].blank?
    @client.name = @client.name.to_s.strip
    respond_to do |format|
			ActiveRecord::Base.transaction do
	      if @client.update(client_params)
					params[:donor_client_products].to_a.each do |donor_client_product_id|
						donor_client_product = Product.find(donor_client_product_id)
						name = "#{@client.name} (#{donor_client_product.name})"
						@client.products.create! parent_id: donor_client_product_id, name: name, tag_list: [name]
					end

	        format.html { redirect_to client_products_path(client_id: @client.id), notice: 'Client was successfully updated.'}
	        format.json { head :no_content }
	      else
	        @clients = Client.where("id <> ?", @client.id)
	        format.html { render action: 'edit' }
	        format.json { render json: @client.errors, status: :unprocessable_entity }
	      end
			end
    end
  end

  # DELETE /clients/1
  # DELETE /clients/1.json
  def destroy
    @client.destroy
    respond_to do |format|
      format.html { redirect_to clients_url, notice: 'Client was successfully deleted.'}
      format.json { head :no_content }
    end
  end

  def aae_templates
  	@client_aae_template_types = %w(introduction call_to_action ending transition general bridge_to_subject collage credits subscription)
  	@project_type = params[:project_type] || @client_aae_template_types.first
  end

  def subject_videos
    #limit = 50
		@search = @client.source_videos.search(params[:q])
    @source_videos = @search.result
    #.page(params[:page]).per(limit)
		render 'clients/subject_videos/client_videos'
  end

	def donor_videos
		@available_donor_videos = SourceVideo.joins(:client).where("clients.id" => @client.donors.pluck(:id)).group_by(&:client)
		render 'clients/subject_videos/donor_videos'
	end

  def general_image_tags

  end

  def source_video_image_tags

  end

  def update_general_image_tags
    parameters = params.require(:client).permit(:id, :tag_list, :client_name_tag_list)
    parameters[:tag_list] = sanitize_tags(parameters[:tag_list])
    parameters[:client_name_tag_list] = sanitize_tags(parameters[:client_name_tag_list])
    @client.update_attributes(parameters)
    render "clients/general_image_tags"
  end

  def update_source_video_image_tags
    render "clients/source_video_image_tags"
  end

  def assign_accounts_to_bot_server
    bot_server_id = params[:bot_server_id].present? ? params[:bot_server_id] : nil
    EmailAccount.where(client_id: @client.id).update_all(bot_server_id: bot_server_id)
    respond_to do |format|
      format.json {head :no_content}
    end
  end

  def legend
    respond_to do |format|
      format.html { render 'legend', layout: false, locals: { client: @client } }
    end
  end

	def industry_association_with_donors
		@client ||= Client.new
		respond_to do |format|
      format.html { render partial: 'clients/form/association_with_donors', layout: false, locals: {industry_id: params[:industry_id]} }
    end
	end

  def assets

  end

  def assets_images
      @rejected_images_ids = []
      search = { total: 0, items: [] }
      params[:limit] = IMAGES_COUNT_DEFAULT_LIMIT unless params[:limit].present?
      @rejected_images_ids = Artifacts::RejectedImage.select(:source_id).distinct.where(source_type: "Artifacts::Image").pluck(:source_id)
      client_id = nil
      client_id = @client.id if params[:target] == 'client'
      if params[:target] == 'donors' && @client.donors.present?
        client_id = if params[:donor_id].present?
          params[:donor_id]
        else
          @client.donors.map(&:id).join(",")
        end
      end
      params[:industry_id] = @client.industry.id if params[:target] == 'industry' && @client.industry.present?
      options = params.merge(
        { client_id: client_id, page: params[:page], limit: params[:limit], rejected_images_ids: @rejected_images_ids }
      )
      search = Artifacts::Image.list(options)
      @total_count = search[:total]
      @images = Kaminari.paginate_array(
        search[:items],
        total_count: search[:total]
      ).page(params[:page]).per(params[:limit])
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_client
      id = params[:id] || params[:client_id]
      @client = Client.find(id)
			@client.remove_logo = false
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def client_params
      params.require(:client).permit!
    end

    def sanitize_tags(tags)
      tags.to_s.split(',').reject(&:blank?).map{|e|e.to_s.mb_chars.downcase.to_s}.uniq
    end
end
