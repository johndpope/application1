module ClientAssets
  extend ActiveSupport::Concern
	def get_assets
    @assets = {}
    youtube_setups = YoutubeSetup.where(client_id: @client.id).order(created_at: :asc)
    industry = @client.industry
    client_and_donors = []
    client_and_donors << @client
    client_and_donors += @client.donors
    @assets[:clients] = []
    client_and_donors.each do |client|
      client_item = {}
      client_item[:id] = client.id
      client_item[:name] = client.name
      client_item[:logo_url] = client.try(:logo).try(:url)
      client_item[:short_descriptions] = Wording.where(resource_id: client.id, resource_type: 'Client', name: "short_description").size.to_s(:delimited)
      client_item[:long_descriptions] = Wording.where(resource_id: client.id, resource_type: 'Client', name: "long_description").size.to_s(:delimited)
      #fix
      all_images = Artifacts::Image.where(client_id: client.id).size
      high_res_images = Artifacts::Image.where("client_id = ? AND width >= ?", client.id, Artifacts::Image::HIGH_RESOLUTION_WIDTH_LIMIT).size
      low_res_images = all_images - high_res_images
      client_item[:images] = all_images.to_s(:delimited)
      client_item[:high_res_images] = high_res_images.to_s(:delimited)
      client_item[:low_res_images] = low_res_images.to_s(:delimited)
      client_item[:tags] = client.tag_list.size.to_s(:delimited)
      social_links_fields = ["website", "blog_url", "youtube_url", "google_plus_url", "facebook_url", "twitter_url", "linkedin_url", "instagram_url", "pinterest_url"]
      social_links_fields.delete_if {|f| client[f].present?}
      client_item[:missing_social_links] = social_links_fields
      client_item[:total_landing_pages] = client.client_landing_pages.size.to_s(:delimited) if @client.id == client.id
      @assets[:clients] << client_item
    end

    @assets[:industry] = {}
    @assets[:industry][:id] = industry.id
    @assets[:industry][:name] = industry.name
    @assets[:industry][:short_descriptions] = Wording.where(resource_id: industry.id, resource_type: 'Industry', name: "short_description").size.to_s(:delimited)
    @assets[:industry][:long_descriptions] = Wording.where(resource_id: industry.id, resource_type: 'Industry', name: "long_description").size.to_s(:delimited)
    @assets[:industry][:tags] = industry.tag_list.size.to_s(:delimited)
    #fix
    all_industry_images = Artifacts::Image.where(industry_id: industry.id).size
    high_res_industry_images = Artifacts::Image.where("industry_id = ? AND width >= ?", industry.id, Artifacts::Image::HIGH_RESOLUTION_WIDTH_LIMIT).size
    low_res_industry_images = all_industry_images - high_res_industry_images
    @assets[:industry][:images] = all_industry_images.to_s(:delimited)
    @assets[:industry][:high_res_images] = high_res_industry_images.to_s(:delimited)
    @assets[:industry][:low_res_images] = low_res_industry_images.to_s(:delimited)

    @assets[:products] = []
    @client.products.each do |product|
      product_item = {}
      product_item[:id] = product.id
      product_item[:client_id] = product.client_id
      product_item[:name] = product.name
      product_item[:logo_url] = product.try(:logo).try(:url)
      product_item[:short_descriptions] = Wording.where(resource_id: product.id, resource_type: 'Product', name: "short_description").size.to_s(:delimited)
      product_item[:long_descriptions] = Wording.where(resource_id: product.id, resource_type: 'Product', name: "long_description").size.to_s(:delimited)
      product_item[:short_statements] = Wording.where(resource_id: product.id, resource_type: 'Product', name: "short_statement").size.to_s(:delimited)
      product_item[:tags] = product.tag_list.size.to_s(:delimited)
      product_item[:ready_subject_videos] = SourceVideo.where(product_id: product.id, ready_for_production: true).size.to_s(:delimited)
      product_item[:total_subject_videos] = SourceVideo.where(product_id: product.id).size.to_s(:delimited)
      product_item[:landing_pages] = ClientLandingPage.where(client_id: @client.id, product_id: product.id).size.to_s(:delimited)
      if product.parent.present?
        parent_product = product.parent
        parent_product_item = {}
        parent_product_item[:id] = parent_product.id
        parent_product_item[:client_id] = parent_product.client_id
        parent_product_item[:name] = parent_product.name
        parent_product_item[:logo_url] = parent_product.try(:logo).try(:url)
        parent_product_item[:short_descriptions] = Wording.where(resource_id: parent_product.id, resource_type: 'Product', name: "short_description").size.to_s(:delimited)
        parent_product_item[:long_descriptions] = Wording.where(resource_id: parent_product.id, resource_type: 'Product', name: "long_description").size.to_s(:delimited)
        parent_product_item[:short_statements] = Wording.where(resource_id: parent_product.id, resource_type: 'Product', name: "short_statement").size.to_s(:delimited)
        parent_product_item[:tags] = parent_product.tag_list.size.to_s(:delimited)
        parent_product_item[:ready_subject_videos] = SourceVideo.where(product_id: parent_product.id, ready_for_production: true).size.to_s(:delimited)
        parent_product_item[:total_subject_videos] = SourceVideo.where(product_id: parent_product.id).size.to_s(:delimited)
        parent_product_item[:landing_pages] = ClientLandingPage.where(product_id: parent_product.id).size.to_s(:delimited)
        product_item[:parent] = parent_product_item
      end
      @assets[:products] << product_item
    end

    # youtube_setups.each_with_index do |ys, index|
    #   email_accounts_setup = ys.email_accounts_setup
    #   products = ys.email_accounts_setup.contract.products
    #   item = {}
    #   item[:id] = ys.id
    #   item[:name] = products.map(&:name).join(", ")
    #
    #   item[:other_short_descriptions] = Wording.where(resource_id: ys.id, resource_type: 'YoutubeSetup', name: "short_description").size.to_s(:delimited)
    #   item[:other_long_descriptions] = Wording.where(resource_id: ys.id, resource_type: 'YoutubeSetup', name: "long_description").size.to_s(:delimited)
    #
    #   item[:other_channel_tags] = ys.other_business_channel_tag_list.size.to_s(:delimited)
    #   item[:other_video_tags] = ys.other_business_video_tag_list.size.to_s(:delimited)
    #
    #   conditions = if email_accounts_setup.cities.present?
    #     nil
    #   elsif email_accounts_setup.states.present?
    #     state_names = Geobase::Region.where("id in (?)", email_accounts_setup.states.map(&:to_i)).pluck(:name).map(&:downcase)
    #     conditions = "LOWER(region1) in (#{state_names.to_s.gsub("'", "''").gsub("[", "").gsub("]", "").gsub("\"", "'")})"
    #   elsif email_accounts_setup.counties.present?
    #     query = "SELECT LOWER(geobase_regions.name) as name, LOWER(parents_geobase_regions.name) as parent_name FROM geobase_regions INNER JOIN geobase_regions parents_geobase_regions ON parents_geobase_regions.id = geobase_regions.parent_id WHERE geobase_regions.id in (#{email_accounts_setup.counties.join(',')})"
    #     results = ActiveRecord::Base.connection.execute(query).to_a
    #     conditions_array = []
    #     results.each{|e| conditions_array << "(LOWER(region2) = '#{e['name'].gsub("'", "''")}' AND LOWER(region1) = '#{e['parent_name'].gsub("'", "''")}')" }
    #     conditions_array.join(" OR ")
    #   end
    #   item[:locality_images] = if conditions.nil?
    #     Geobase::Locality.joins("LEFT OUTER JOIN geobase_regions ON geobase_regions.id = geobase_localities.primary_region_id LEFT OUTER JOIN geobase_countries ON geobase_countries.id = geobase_regions.country_id").select("geobase_localities.*, locality_artifacts_images_count(geobase_localities.id, geobase_localities.name, geobase_localities.primary_region_id) AS images_count").where("locality_artifacts_images_count(geobase_localities.id, geobase_localities.name, geobase_localities.primary_region_id) > 0 AND geobase_localities.id in (?)", email_accounts_setup.cities.map(&:to_i)).map(&:images_count).inject(0){|sum,x| sum + x }.to_s(:delimited)
    #   elsif conditions.present?
    #     Artifacts::Image.distinct.where(conditions).size.to_s(:delimited)
    #   else
    #     "-"
    #   end
    #   @assets << item
    # end
    @client_aae_template_types = %w(introduction call_to_action ending transition general bridge_to_subject collage subscription)
    @project_text_types = Templates::AaeProjectText::TEXT_GROUPES.keys
    @clients = Client.where(is_active: true).order(:name)
    @dynamic_texts_report = {}
    Templates::AaeProjectDynamicText.unscoped.where("client_id = ?", @client.id).group('1,2').order('1,2').pluck('project_type, text_type, count(*)').each { |e| @dynamic_texts_report[e[0]] = {} unless @dynamic_texts_report[e[0]].present?; @dynamic_texts_report[e[0]][e[1]] = e[2] }
    @source_videos_report = {}
    SourceVideo.joins("LEFT OUTER JOIN templates_aae_project_dynamic_texts AS tapdts ON tapdts.subject_video_id = source_videos.id LEFT OUTER JOIN products ON products.id = source_videos.product_id LEFT OUTER JOIN clients ON clients.id = products.client_id").where("clients.id = ?", @client.id).group('1,2,3').order('1,2,3').pluck('source_videos.id, tapdts.project_type, tapdts.text_type, count(*)').each { |e| @source_videos_report[e[0]] = {} unless @source_videos_report[e[0]].present?; @source_videos_report[e[0]][e[1]] = {} unless @source_videos_report[e[0]][e[1]].present?; @source_videos_report[e[0]][e[1]][e[2]] = e[3] }
  end
end
