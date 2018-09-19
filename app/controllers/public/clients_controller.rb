class Public::ClientsController < Public::BaseController
  include ClientAssets
  before_action :get_assets, only: [:assets]
	ITEMS_LIMIT = 25
  PAGE_LIMIT = 3
  RANKS_LIMIT = 4

	def dashboard
	end

  def report
    respond_to do |format|
      @client = Client.find_by_public_profile_uuid(params[:client_id])
      Utils.save_web_screenshot(@client, "#{Rails.configuration.routes_default_url_options[:host]}#{Rails.application.routes.url_helpers.public_client_youtube_videos_path(@client.public_profile_uuid, status: "done")}", 1600, 1600) unless @client.screenshots.present?
      localitys = Geobase::Locality.where("id in (?)", EmailAccount.where("client_id = ?", @client.id).pluck(:locality_id).uniq).pluck(:id, :primary_region_id)
      @locations = {}
      localitys.each do |loc, reg|
        locality = Geobase::Locality.find(loc).name
        region = Geobase::Region.find(reg).code.split(Geobase::Region::SEPARATOR).first.split("-").last
        @locations[locality] = region
      end
      locality_ids = localitys.map(&:first)
      @youtube_video_search_ranks_by_google = []
      @youtube_video_search_ranks_by_youtube = []
      ranks_join = "
        LEFT JOIN youtube_video_search_phrases ON youtube_video_search_phrases.id = youtube_video_search_ranks.youtube_video_search_phrase_id
        LEFT JOIN youtube_videos ON youtube_videos.id = youtube_video_search_phrases.youtube_video_id
        LEFT JOIN youtube_channels ON youtube_channels.id = youtube_videos.youtube_channel_id
        LEFT JOIN google_accounts ON google_accounts.id = youtube_channels.google_account_id
        LEFT JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id AND email_accounts.email_item_type = 'GoogleAccount'
        LEFT JOIN clients ON clients.id = email_accounts.client_id
      "
      locality_ids.each do |loc_id|
        @youtube_video_search_ranks_by_google << YoutubeVideoSearchRank.joins(ranks_join).where("clients.id = ? AND youtube_video_search_ranks.search_type = ? AND youtube_video_search_ranks.rank IS NOT NULL AND ((youtube_videos.publication_date < youtube_video_search_ranks.created_at AND youtube_videos.rotate_content_date IS NULL) OR (youtube_videos.rotate_content_date IS NOT NULL AND youtube_videos.rotate_content_date < youtube_video_search_ranks.created_at)) AND youtube_video_search_ranks.page <= ? AND email_accounts.locality_id = ?", @client.id, YoutubeVideoSearchRank.search_type.find_value(:google).value, PAGE_LIMIT, loc_id).order("youtube_video_search_ranks.rank ASC, youtube_video_search_ranks.result_type ASC, youtube_video_search_phrases.disabled DESC, youtube_video_search_ranks.in_box_position ASC, youtube_video_search_ranks.created_at DESC").first

        @youtube_video_search_ranks_by_youtube << YoutubeVideoSearchRank.joins(ranks_join).where("clients.id = ? AND youtube_video_search_ranks.search_type = ? AND youtube_video_search_ranks.rank IS NOT NULL AND ((youtube_videos.publication_date < youtube_video_search_ranks.created_at AND youtube_videos.rotate_content_date IS NULL) OR (youtube_videos.rotate_content_date IS NOT NULL AND youtube_videos.rotate_content_date < youtube_video_search_ranks.created_at)) AND youtube_video_search_ranks.page <= ? AND email_accounts.locality_id = ?", @client.id, YoutubeVideoSearchRank.search_type.find_value(:youtube).value, PAGE_LIMIT, loc_id).order("youtube_video_search_ranks.rank ASC, youtube_video_search_ranks.created_at DESC").uniq.first
      end

      @youtube_video_search_ranks_by_google.compact!
      @youtube_video_search_ranks_by_youtube.compact!

      if @youtube_video_search_ranks_by_google.size < RANKS_LIMIT
        @youtube_video_search_ranks_by_google << YoutubeVideoSearchRank.joins(ranks_join).where("clients.id = ? AND youtube_video_search_ranks.search_type = ? AND youtube_video_search_ranks.rank IS NOT NULL AND ((youtube_videos.publication_date < youtube_video_search_ranks.created_at AND youtube_videos.rotate_content_date IS NULL) OR (youtube_videos.rotate_content_date IS NOT NULL AND youtube_videos.rotate_content_date < youtube_video_search_ranks.created_at)) AND youtube_video_search_ranks.page <= ? AND youtube_video_search_ranks.id NOT IN (?)", @client.id, YoutubeVideoSearchRank.search_type.find_value(:google).value, PAGE_LIMIT, @youtube_video_search_ranks_by_google.map(&:id)).order("youtube_video_search_ranks.rank ASC, youtube_video_search_ranks.result_type ASC, youtube_video_search_phrases.disabled DESC, youtube_video_search_ranks.in_box_position ASC, youtube_video_search_ranks.created_at DESC").limit(RANKS_LIMIT - @youtube_video_search_ranks_by_google.size)
        @youtube_video_search_ranks_by_google.flatten!
        @youtube_video_search_ranks_by_google.compact!
      else
        @youtube_video_search_ranks_by_google.sort! { |a, b|  a.rank <=> b.rank }
      end

      if @youtube_video_search_ranks_by_youtube.size < RANKS_LIMIT
        @youtube_video_search_ranks_by_youtube << YoutubeVideoSearchRank.joins(ranks_join).where("clients.id = ? AND youtube_video_search_ranks.search_type = ? AND youtube_video_search_ranks.rank IS NOT NULL AND ((youtube_videos.publication_date < youtube_video_search_ranks.created_at AND youtube_videos.rotate_content_date IS NULL) OR (youtube_videos.rotate_content_date IS NOT NULL AND youtube_videos.rotate_content_date < youtube_video_search_ranks.created_at)) AND youtube_video_search_ranks.page <= ? AND youtube_video_search_ranks.id NOT IN (?)", @client.id, YoutubeVideoSearchRank.search_type.find_value(:youtube).value, PAGE_LIMIT, @youtube_video_search_ranks_by_youtube.map(&:id)).order("youtube_video_search_ranks.rank ASC, youtube_video_search_ranks.created_at DESC").uniq.limit(RANKS_LIMIT - @youtube_video_search_ranks_by_youtube.size)
        @youtube_video_search_ranks_by_youtube.flatten!
        @youtube_video_search_ranks_by_youtube.compact!
      else
        @youtube_video_search_ranks_by_youtube.sort! { |a, b|  a.rank <=> b.rank }
      end
      # @youtube_video_search_ranks_by_google = YoutubeVideoSearchRank.joins(ranks_join).where("clients.id = ? AND youtube_video_search_ranks.search_type = ? AND youtube_video_search_ranks.rank IS NOT NULL AND ((youtube_videos.publication_date < youtube_video_search_ranks.created_at AND youtube_videos.rotate_content_date IS NULL) OR (youtube_videos.rotate_content_date IS NOT NULL AND youtube_videos.rotate_content_date < youtube_video_search_ranks.created_at)) AND youtube_video_search_ranks.page <= 3", @client.id, YoutubeVideoSearchRank.search_type.find_value(:google).value).order("youtube_video_search_ranks.rank ASC, youtube_video_search_ranks.result_type ASC, youtube_video_search_ranks.created_at DESC").uniq
      #
      # @youtube_video_search_ranks_by_youtube = YoutubeVideoSearchRank.joins(ranks_join).where("clients.id = ? AND youtube_video_search_ranks.search_type = ? AND youtube_video_search_ranks.rank IS NOT NULL AND ((youtube_videos.publication_date < youtube_video_search_ranks.created_at AND youtube_videos.rotate_content_date IS NULL) OR (youtube_videos.rotate_content_date IS NOT NULL AND youtube_videos.rotate_content_date < youtube_video_search_ranks.created_at)) AND youtube_video_search_ranks.page <= 3", @client.id, YoutubeVideoSearchRank.search_type.find_value(:youtube).value).order("youtube_video_search_ranks.rank ASC, youtube_video_search_ranks.created_at DESC").uniq

      @youtube_video_example = YoutubeVideo.joins("
        LEFT OUTER JOIN youtube_channels ON youtube_channels.id = youtube_videos.youtube_channel_id
        LEFT OUTER JOIN google_accounts ON google_accounts.id = youtube_channels.google_account_id
        LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id
        LEFT OUTER JOIN clients ON clients.id = email_accounts.client_id
        LEFT OUTER JOIN screenshots ON screenshots.screenshotable_id = youtube_videos.id AND screenshots.screenshotable_type = 'YoutubeVideo'").where("
          clients.id = ?
          AND screenshots.action_type = 'web_screenshot'
          AND youtube_channels.blocked IS NOT TRUE
          AND youtube_channels.youtube_channel_id IS NOT NULL
          AND youtube_videos.youtube_video_id IS NOT NULL
          AND youtube_videos.is_active = TRUE", @client.id).last

      @youtube_video_screenshot = @youtube_video_example.present? ? @youtube_video_example.screenshots.where("screenshots.action_type = 'web_screenshot'").last : nil

      @youtube_channel_example = YoutubeChannel.joins("
        LEFT OUTER JOIN google_accounts ON google_accounts.id = youtube_channels.google_account_id
        LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id
        LEFT OUTER JOIN clients ON clients.id = email_accounts.client_id
        LEFT OUTER JOIN screenshots ON screenshots.screenshotable_id = youtube_channels.id
        AND screenshots.screenshotable_type = 'YoutubeChannel'").where("
          clients.id = ?
          AND screenshots.action_type = 'web_screenshot'
          AND youtube_channels.channel_type = ?
          AND youtube_channels.blocked IS NOT TRUE
          AND youtube_channels.youtube_channel_id IS NOT NULL", @client.id, YoutubeChannel.channel_type.find_value(:business).value).last

      @youtube_channel_screenshot = @youtube_channel_example.present? ? @youtube_channel_example.screenshots.where("screenshots.action_type = 'web_screenshot'").last : nil


      format.html
      format.pdf{
        render pdf: "report",
        :margin => { :top => 0, :bottom => 0, :left => 0, :right => 0}
      }
    end
  end

  def dashboard_content
    respond_to do |format|
      format.html { render partial: "public/clients/dashboard/#{params[:part]}" }
    end
  end

	def show
		redirect_to public_client_dashboard_path(@client)
	end

	def youtube_channels
    youtube_channels_join = @client.id == 7 ? "" : "LEFT OUTER JOIN google_accounts ON google_accounts.id = youtube_channels.google_account_id LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id"
    params[:limit] = ITEMS_LIMIT unless params[:limit].present?
    @search = case params[:status]
      when 'done'
        YoutubeChannel.distinct.joins(youtube_channels_join).by_linked('true').by_ready('true').by_filled('true').by_is_active('true').by_is_verified_by_phone('true')
      when 'pending'
        YoutubeChannel.distinct.joins(youtube_videos_join).where("youtube_channels.linked IS NOT TRUE OR youtube_channels.ready IS NOT TRUE OR youtube_channels.filled IS NOT TRUE OR youtube_channels.is_active IS NOT TRUE OR youtube_channels.is_verified_by_phone IS NOT TRUE")
      else
        YoutubeChannel.distinct.joins(youtube_channels_join).by_client_id(@client.id.to_s).by_channel_type(params[:channel_type]).order(:channel_type)
    end
		@youtube_channels = @search.by_client_id(@client.id.to_s).by_channel_type(params[:channel_type]).order("youtube_channels.publication_date DESC NULLS LAST, youtube_channels.id DESC").page(params[:page]).per(params[:limit])
	end

	def youtube_videos
    youtube_videos_join = @client.id == 7 ? "LEFT OUTER JOIN youtube_channels ON youtube_channels.id = youtube_videos.youtube_channel_id LEFT OUTER JOIN youtube_video_annotations ON youtube_video_annotations.youtube_video_id = youtube_videos.id LEFT OUTER JOIN youtube_video_cards ON youtube_video_cards.youtube_video_id = youtube_videos.id LEFT OUTER JOIN call_to_action_overlays ON call_to_action_overlays.youtube_video_id = youtube_videos.id" : "LEFT OUTER JOIN youtube_channels ON youtube_channels.id = youtube_videos.youtube_channel_id LEFT OUTER JOIN google_accounts ON google_accounts.id = youtube_channels.google_account_id LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id LEFT OUTER JOIN geobase_localities ON geobase_localities.id = email_accounts.locality_id LEFT OUTER JOIN geobase_regions ON geobase_regions.id = geobase_localities.primary_region_id LEFT OUTER JOIN geobase_countries ON geobase_countries.id = geobase_regions.country_id LEFT OUTER JOIN geobase_regions regions ON regions.id = email_accounts.region_id LEFT OUTER JOIN geobase_countries countries ON countries.id = regions.country_id LEFT OUTER JOIN clients ON clients.id = email_accounts.client_id LEFT OUTER JOIN youtube_video_annotations ON youtube_video_annotations.youtube_video_id = youtube_videos.id LEFT OUTER JOIN youtube_video_cards ON youtube_video_cards.youtube_video_id = youtube_videos.id LEFT OUTER JOIN call_to_action_overlays ON call_to_action_overlays.youtube_video_id = youtube_videos.id"
    params[:limit] = ITEMS_LIMIT unless params[:limit].present?
    @search = case params[:status]
      when 'done'
        YoutubeVideo.distinct.joins(youtube_videos_join).by_client_id(@client.id).where("youtube_videos.deleted IS NOT TRUE AND youtube_videos.is_active = TRUE AND youtube_videos.youtube_video_id IS NOT NULL AND youtube_videos.youtube_video_id <> ''")
      when 'pending'
        YoutubeVideo.distinct.joins(youtube_videos_join).by_client_id(@client.id).where("youtube_videos.deleted IS NOT TRUE AND (youtube_videos.youtube_video_id IS NULL OR youtube_videos.youtube_video_id = '')", @client.id)
      else
        YoutubeVideo.distinct.joins(youtube_videos_join).by_client_id(@client.id).where("youtube_videos.deleted IS NOT TRUE", @client.id)
    end
		@youtube_videos = @search.by_posted_on_google_plus(params[:posted_on_google_plus]).order("youtube_videos.publication_date DESC NULLS LAST, youtube_videos.id DESC").page(params[:page]).per(params[:limit])
	end

	def client_landing_pages
    params[:limit] = ITEMS_LIMIT unless params[:limit].present?
    @search = case params[:status]
      when 'done'
        exclude_ids = ClientLandingPage.joins("INNER JOIN associated_websites ON associated_websites.client_landing_page_id = client_landing_pages.id").where("client_landing_pages.client_id = ? AND associated_websites.linked IS NOT TRUE", @client.id).pluck(:id)
        exclude_ids << -1
        ClientLandingPage.joins("INNER JOIN associated_websites ON associated_websites.client_landing_page_id = client_landing_pages.id").where("client_landing_pages.client_id = ? AND client_landing_pages.id not in (?)", @client.id, exclude_ids).uniq
      when 'pending'
        ClientLandingPage.joins("INNER JOIN associated_websites ON associated_websites.client_landing_page_id = client_landing_pages.id")
          .where("client_landing_pages.client_id = ? AND associated_websites.linked IS NOT TRUE", @client.id).uniq
      else
        ClientLandingPage.joins("INNER JOIN associated_websites ON associated_websites.client_landing_page_id = client_landing_pages.id")
          .where("client_landing_pages.client_id = ?", @client.id).uniq
    end
    #@piwik_statistics = PiwikService.visitors_statistics_json
    @client_landing_pages = @search.page(params[:page]).order("client_landing_pages.created_at DESC").per(params[:limit])
	end

  def assets
  end
end
