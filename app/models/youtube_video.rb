require 'google/api_client'
require 'mime/types'

class YoutubeVideo < ActiveRecord::Base
	include Reversible

	PRIVACY_LEVELS = {
		'Unlisted' => 1,
		'Public' => 2,
		'Private' => 3
	}

	ALLOW_COMMENTS = {
		'All' => 1,
		'Approved' => 2
	}

	LICENSES = {
		'Standard Youtube License' => 1,
		'Creative Commons - Attribution' => 2
	}

	SYNDICATIONS = {
		'Everywhere' => 1,
		'Monetized platforms' => 2
	}

	CATEGORIES = {
		'Autos & Vehicles' => 1,
		'Comedy' => 2,
		'Education' => 3,
		'Entertainment' => 4,
		'Film & Animation' => 5,
		'Gaming' => 6,
		'Howto & Style' => 7,
		'Music' => 8,
		'News & Politics' => 9,
		'Nonprofits & Activism' => 10,
		'People & Blogs' => 11,
		'Pets & Animals' => 12,
		'Science & Technology' => 13,
		'Sports' => 14,
		'Travel & Events' => 15
	}

	VIDEOS_3DS = {
		'No preference' => 1,
		'Disable 3D for this video' => 2,
		'Please make this video 3D' => 3,
		'This video is already 3D' => 4
	}

	YOUTUBE_THUMBNAIL_PATH = 'https://img.youtube.com/vi'

	# Youtube limit 5000
	VIDEO_DESCRIPTION_LIMIT = 4950
	SCREENSHOT_PATH = '/out/screen/youtube_video/<id>.jpg'
	VIDEO_NAME_DELIMITERS = ['/', '-', '|']
	CARDS_LIMIT = 5

	# Youtube limit 100
	VIDEO_NAME_LIMIT = 100
	TAGS_LIMIT = 50
  TAGS_CHARS_LIMIT = 500
  SCREENSHOTS_LIMIT = 20
  TAG_SIZE_LIMIT = 30
  SEARCH_PHRASES_LIMIT = 10

	extend FriendlyId
	friendly_id :title, use: :slugged

	extend Enumerize
	enumerize :privacy_level, :in => PRIVACY_LEVELS
	enumerize :allow_comments, :in => ALLOW_COMMENTS
	enumerize :license, :in => LICENSES
	enumerize :syndication, :in => SYNDICATIONS
	enumerize :category, :in => CATEGORIES
	enumerize :video_3d, :in => VIDEOS_3DS

	has_one :video, as: :video_item, dependent: :destroy
	has_one :call_to_action_overlay, dependent: :destroy
	has_many :adwords_campaign_groups, dependent: :destroy
	has_many :screenshots, as: :screenshotable, dependent: :destroy
	has_many :phone_usages, :as => :phone_usageable
	has_many :youtube_video_annotations, dependent: :destroy
	has_many :youtube_video_cards, dependent: :destroy
  has_many :yt_statistics, as: :resource, dependent: :destroy
  has_many :youtube_video_search_phrases, dependent: :destroy

	belongs_to :youtube_channel
	belongs_to :source_video
	belongs_to :language
	belongs_to :blended_video

	validates :youtube_channel_id, :presence => true
	validates :title, :presence => true
	validates :youtube_video_id, uniqueness: true, allow_nil: true
	validates_length_of :youtube_video_cards, maximum: CARDS_LIMIT
  #validates_length_of :tags, :maximum => TAGS_CHARS_LIMIT, :allow_blank => true
  validate :tags_length_validation

  before_save :change_fields_to_update
	after_save :update_adwords_campaign_groups_and_call_to_action_overlay
  after_create :generate_search_phrases

	has_one :client, through: :youtube_channel

	attr_accessor :thumbnail
	attr_accessor :skip_thumbnail_presence_validation, :skip_video_presence_validation

	has_attached_file :thumbnail, path: ':rails_root/public/system/images/youtube_video_thumbnails/:id_partition/:style/:basename.:extension', url:  '/system/images/youtube_video_thumbnails/:id_partition/:style/:basename.:extension', styles: { thumb: '150x150>' }
	validates_attachment :thumbnail, content_type: { content_type: ['image/png','image/jpeg', 'image/gif', 'image/bmp'] }, size: { greater_than: 0.bytes, less_than: 2.megabytes }, unless: :skip_thumbnail_presence_validation
	validates :thumbnail, dimensions: { minimum_width: 1280, minimum_height: 720 }

	def self.statistics()
		JSON.parse(ActiveRecord::Base.connection.execute('SELECT youtube_video_statistics_json() AS result')[0]['result'])
	end

	def self.time_periods
		ActiveRecord::Base.connection.execute('SELECT EXTRACT (YEAR FROM created_at::date) as _year, EXTRACT (MONTH FROM created_at::date) as _month FROM youtube_videos GROUP BY _year, _month ORDER BY _year desc, _month desc').to_a
	end

  def mediainfo
    self.blended_video.present? && self.blended_video.file.present? ? Mediainfo.new(self.blended_video.file.path) : nil
  end

  def duration
    self.mediainfo.present? ? self.mediainfo.video.duration / 1000 : nil
  end

	def splitted_tags()
		return self.tags ? self.tags.split(',') : []
	end

	def thumbnail_urls()
		return {
			default: "#{Setting.get_value_by_name('YoutubeVideo::YOUTUBE_THUMBNAIL_PATH')}/#{self.youtube_video_id}/default.jpg",
			medium: "#{Setting.get_value_by_name('YoutubeVideo::YOUTUBE_THUMBNAIL_PATH')}/#{self.youtube_video_id}/mqdefault.jpg",
			standard: "#{Setting.get_value_by_name('YoutubeVideo::YOUTUBE_THUMBNAIL_PATH')}/#{self.youtube_video_id}/sddefault.jpg",
			high: "#{Setting.get_value_by_name('YoutubeVideo::YOUTUBE_THUMBNAIL_PATH')}/#{self.youtube_video_id}/hqdefault.jpg",
			max_res: "#{Setting.get_value_by_name('YoutubeVideo::YOUTUBE_THUMBNAIL_PATH')}/#{self.youtube_video_id}/maxresdefault.jpg"
		}
	end

	def url()
		return "#{Setting.get_value_by_name('YoutubeChannel::YOUTUBE_URL')}/watch?v=#{self.youtube_video_id}" if self.youtube_video_id.present?
	end

	def to_param
		id
	end

  def add_posting_time
    gaa = youtube_channel.google_account.google_account_activity
    if gaa.youtube_video_upload_start.present?
      if self.publication_date.present? && self.publication_date > gaa.youtube_video_upload_start.last
        last_published_youtube_video = YoutubeVideo.where("youtube_channel_id = ? AND publication_date > ? AND id <> ? AND publication_date IS NOT NULL", youtube_channel.id, gaa.youtube_video_upload_start.last, self.id).order("publication_date DESC NULLS LAST").first
        starting_point = last_published_youtube_video.present? ? last_published_youtube_video.publication_date : gaa.youtube_video_upload_start.last
        time = Time.at(self.publication_date - starting_point).utc
        self.posting_time = time.hour*3600 + time.min*60 + time.sec if time.hour == 0
        self.save
      end
    end
  end

  def add_google_plus_upload_time
    gaa = youtube_channel.google_account.google_account_activity
    if gaa.google_plus_video_add_start.present?
      if self.posted_on_google_plus_at.present? && self.posted_on_google_plus_at > gaa.google_plus_video_add_start.last
        last_published_youtube_video = YoutubeVideo.where("youtube_channel_id = ? AND posted_on_google_plus_at > ? AND id <> ? AND posted_on_google_plus_at IS NOT NULL", youtube_channel.id, gaa.google_plus_video_add_start.last, self.id).order("posted_on_google_plus_at DESC NULLS LAST").first
        starting_point = last_published_youtube_video.present? ? last_published_youtube_video.posted_on_google_plus_at : gaa.google_plus_video_add_start.last
        time = Time.at(self.posted_on_google_plus_at - starting_point).utc
        self.google_plus_upload_time = time.hour*3600 + time.min*60 + time.sec if time.hour == 0
        self.save
      end
    end
  end

	def json
		json_object = {}
		json_object =  JSON.parse(self.to_json)
    json_object.delete("yt_stat_json")
		json_object['video_relative_path'] = self.blended_video.present? && self.blended_video.file.present? ? self.blended_video.file.url(:original).gsub("/system/blended_videos/", "") : ""
		json_object['video_file_name'] = self.blended_video.present? ? self.blended_video.file_file_name : ""
		json_object['video_location'] = ''
		json_object['video_location'] = if self.youtube_channel && self.youtube_channel.google_account && self.youtube_channel.google_account.email_account && self.youtube_channel.google_account.email_account.locality && !self.youtube_channel.google_account.email_account.locality.zip_codes.empty?
			zip_code = self.youtube_channel.google_account.email_account.locality.zip_codes.shuffle.first
			zip_code.latitude.to_s + ' ' + zip_code.longitude.to_s if zip_code.latitude && zip_code.longitude
		end
		json_object['category'] = self.category.try(:value).to_s
		json_object['category_name'] = self.category.to_s
		json_object['youtube_channel_id'] = self.youtube_channel.try(:youtube_channel_id).to_s
    json_object['yc_id'] = self.youtube_channel.try(:id)
		json_object['language'] = self.language.present? ? self.language.name : Language.where("name = 'English'").first.try(:name).to_s
    json_object['description'] = self.description.present? ? self.description.gsub("\r", "").squeeze(" ") : ''
		json_object
	end

	def acceptable_for_uploading?
		[youtube_channel.google_account.email_account.client.try(:is_active), blended_video.try(:file_file_name).present?, youtube_channel.youtube_channel_id.present?, youtube_channel.is_verified_by_phone, !youtube_channel.blocked, !youtube_video_id.present?, !linked, !is_active, !deleted, ready].all?
	end

  def acceptable_for_upload_changes?
		[youtube_channel.google_account.email_account.client.try(:is_active), youtube_channel.youtube_channel_id.present?, youtube_channel.is_verified_by_phone, !youtube_channel.blocked, youtube_video_id.present?, !linked, is_active, !deleted, ready, fields_to_update.present?].all?
	end

  def acceptable_for_deleting?
    [youtube_channel.youtube_channel_id.present?, youtube_video_id.present?, !youtube_channel.blocked, deleted, is_active, ready].all?
  end

  def acceptable_for_posting_on_google_plus?
    [youtube_channel.google_account.email_account.client.try(:is_active), !youtube_channel.blocked, linked, is_active, !deleted, ready, youtube_video_id.present?, !posted_on_google_plus, privacy_level.try(:value) != YoutubeVideo.privacy_level.find_value("Private").value].all?
  end

  def acceptable_for_search_rank?
		has_something_for_rank = false
		rank_check_frequency_days = Setting.get_value_by_name("YoutubeVideoSearchRank::RANK_CHECK_FREQUENCY_DAYS").to_i
		if self.publication_date.present? && self.is_active && self.linked
	    YoutubeVideoSearchRank::SEARCH_TYPES.keys.each do |search_type|
	      self.active_youtube_video_search_phrases.each do |sph|
	        if !YoutubeVideoSearchRank.where("youtube_video_search_phrase_id = ? AND created_at > ? AND search_type = ? AND current = true", sph.id, Time.now - rank_check_frequency_days.days, YoutubeVideoSearchRank.search_type.find_value(search_type).value).present? && ((self.rotate_content_date || self.publication_date) + Setting.get_value_by_name("YoutubeVideoSearchRank::RANK_CHECK_FIRST_TIME_DELAY_DAYS").to_i.day < Time.now)
	          has_something_for_rank = true
	          break
	        end
	      end
	    end
		end
    [has_something_for_rank, publication_date.present? && (publication_date < Time.now - Setting.get_value_by_name("YoutubeVideoSearchRank::RANK_CHECK_FIRST_TIME_DELAY_DAYS").to_i.day), youtube_channel.google_account.email_account.client.try(:is_active), !youtube_channel.blocked, is_active, linked, !deleted, ready, youtube_video_id.present?, privacy_level.try(:value) != YoutubeVideo.privacy_level.find_value("Private").value].all?
  end

  def has_yt_statistics_errors?
    YoutubeVideo.joins("LEFT JOIN yt_statistics ON yt_statistics.resource_id = youtube_videos.id AND yt_statistics.resource_type = 'YoutubeVideo'").where("yt_statistics.resource_id = ? AND yt_statistics.resource_type = 'YoutubeVideo' AND yt_statistics.current = TRUE AND (yt_statistics.processed = FALSE OR yt_statistics.grab_succeded = FALSE) AND youtube_videos.is_active IS TRUE AND youtube_videos.deleted IS NOT TRUE", self.id).exists? ? true : false
  end

  def active_youtube_video_search_phrases
    youtube_video_search_phrases.where("youtube_video_search_phrases.disabled IS NOT TRUE")
  end

	def save_screenshot
    bot_server_url = self.youtube_channel.try(:google_account).try(:email_account).try(:bot_server).try(:path) || Setting.get_value_by_name('EmailAccount::BOT_URL')
		image_url = bot_server_url + Setting.get_value_by_name('YoutubeVideo::SCREENSHOT_PATH').gsub('<id>', self.id.to_s).downcase
		begin
			file = open(image_url)
			screen = Screenshot.new
			screen.image = file
			extension = Rack::Mime::MIME_TYPES.invert[screen.image_content_type]
			screen.image_file_name = File.basename(self.id.to_s)[0..-1] + extension
			self.screenshots << screen
			%x(curl -X GET "#{bot_server_url}/screen_rotate.php?path=youtube_video&file=#{id}")
      screenshots_limit = Setting.get_value_by_name("YoutubeVideo::SCREENSHOTS_LIMIT").to_i
      if self.screenshots.size > screenshots_limit
        screenshots = self.screenshots.sort.to_a
        screenshots.pop
        screenshots = screenshots - screenshots.last(screenshots_limit)
        screenshots.each do |scr|
          scr.destroy if scr.removable
        end
      end
      file.close unless file.closed?
			true
		rescue
			false
		end
	end

  def generate_youtube_video_cards(ready = false, client = nil, call_to_action_texts = [])
    ea = self.youtube_channel.google_account.email_account
    client = client || ea.client
    short_statements = call_to_action_texts
    video_duration = self.duration
    if !client.ignore_landing_pages && self.youtube_video_cards.size < 5
      unless short_statements.present?
        product = self.blended_video.try(:source_video).try(:product)
        source_video = self.blended_video.source_video
        donor_source_video = client.client_donor_source_videos.where(recipient_source_video_id: source_video.id).first.try(:source_video)
        short_statements = Wording.select(:source).where("resource_id = ? AND resource_type = 'SourceVideo' AND name = ? AND LENGTH(source) <= ?", source_video.id, 'short_statement', YoutubeVideoCard::TEASER_TEXT_LIMIT).order("random()").map(&:source)
        short_statements = Wording.select(:source).where("resource_id = ? AND resource_type = 'SourceVideo' AND name = ? AND LENGTH(source) <= ?", donor_source_video.id, 'short_statement', YoutubeVideoCard::TEASER_TEXT_LIMIT).order("random()").map(&:source) if !short_statements.present? && donor_source_video.present?
        short_statements = Wording.select(:source).where("resource_id = ? AND resource_type = 'Product' AND name = ? AND LENGTH(source) <= ?", source_video.product.id, 'short_statement', YoutubeVideoCard::TEASER_TEXT_LIMIT).order("random()").map(&:source) unless short_statements.present?
        short_statements = Wording.select(:source).where("resource_id = ? AND resource_type = 'Product' AND name = ? AND LENGTH(source) <= ?", donor_source_video.product.id, 'short_statement', YoutubeVideoCard::TEASER_TEXT_LIMIT).order("random()").map(&:source) if !short_statements.present? && donor_source_video.try(:product).present?
      end
      client_landing_page = ClientLandingPage.joins("LEFT JOIN associated_websites ON associated_websites.client_landing_page_id = client_landing_pages.id").where("associated_websites.youtube_channel_id = ? AND associated_websites.ready = TRUE AND associated_websites.linked = TRUE AND client_landing_pages.product_id = ?", self.youtube_channel.id, product.id).order("random()").first
      other_channels = YoutubeChannel.joins(:client).where("clients.id = ? AND youtube_channels.youtube_channel_id IS NOT NULL AND youtube_channels.youtube_channel_id <> '' AND youtube_channels.is_active IS TRUE AND youtube_channels.blocked IS NOT TRUE AND youtube_channels.id <> ?", client.id, self.youtube_channel.id).order("random()").first(5)
      short_statements = short_statements.uniq.shuffle.first(5)
      if short_statements.present? && client_landing_page.present? && other_channels.present?
        cards_number = 5
        unless video_duration.present?
          video_duration = 60
          cards_number = 1
        end
        segment = (video_duration - 15) / 4
        cards_number.times do |index|
          rand_time = (1..10).to_a.shuffle.first
          next_segment_start = index * segment + rand_time
          start_time = next_segment_start - next_segment_start % 5
          next_channel = other_channels[index]
          if next_channel.present?
            YoutubeVideoCard.create(youtube_video_id: self.id, teaser_text: short_statements[index], custom_message: [client_landing_page.subdomain.try(:strip), client_landing_page.domain.try(:strip)].reject(&:blank?).join('.'), card_type: YoutubeVideoCard.card_type.find_value("Channel").value, url: next_channel.url, start_time: start_time, ready: ready, linked: false)
          end
        end
      end
    end
  end

  def generate_adwords_and_call_to_action_overlays(ready = false, client = nil, call_to_action_text = nil)
    ea = self.youtube_channel.google_account.email_account
    client = client || ea.client
    email_accounts_setup = ea.email_accounts_setup
		youtube_setup = email_accounts_setup.try(:youtube_setup)
    product = self.blended_video.try(:source_video).try(:product)
    source_video = self.blended_video.source_video
    donor_source_video = client.client_donor_source_videos.where(recipient_source_video_id: source_video.id).first.try(:source_video)
    short_statement = nil
    short_statements = []
    short_statements = Wording.select(:source).where("resource_id = ? AND resource_type = 'SourceVideo' AND name = ? AND LENGTH(source) <= ?", source_video.id, 'short_statement', CallToActionOverlay::HEADLINE_LIMIT).order("random()").map(&:source)
    short_statements = Wording.select(:source).where("resource_id = ? AND resource_type = 'SourceVideo' AND name = ? AND LENGTH(source) <= ?", donor_source_video.id, 'short_statement', CallToActionOverlay::HEADLINE_LIMIT).order("random()").map(&:source) if !short_statements.present? && donor_source_video.present?
    short_statements = Wording.select(:source).where("resource_id = ? AND resource_type = 'Product' AND name = ? AND LENGTH(source) <= ?", source_video.product.id, 'short_statement', CallToActionOverlay::HEADLINE_LIMIT).order("random()").map(&:source) unless short_statements.present?
    short_statements = Wording.select(:source).where("resource_id = ? AND resource_type = 'Product' AND name = ? AND LENGTH(source) <= ?", donor_source_video.product.id, 'short_statement', CallToActionOverlay::HEADLINE_LIMIT).order("random()").map(&:source) if !short_statements.present? && donor_source_video.try(:product).present?
    short_statement = short_statements.first
    client_landing_page = ClientLandingPage.joins("LEFT JOIN associated_websites ON associated_websites.client_landing_page_id = client_landing_pages.id").where("associated_websites.youtube_channel_id = ? AND associated_websites.ready = TRUE AND associated_websites.linked = TRUE AND client_landing_pages.product_id = ?", self.youtube_channel.id, product.id).order("random()").first
    if !client.ignore_landing_pages && client_landing_page.present? && short_statement.present? && self.youtube_video_id.present? && youtube_setup.present? && youtube_setup.use_call_to_action_overlays
      google_account = self.youtube_channel.google_account
      final_url = client_landing_page.page_url
      display_url = final_url.gsub("http://", "").gsub("https://", "")
      if display_url.size > CallToActionOverlay::DISPLAY_URL_LIMIT
        display_url_array = display_url.split(".")
        display_url_array.delete(display_url_array.first)
        display_url = display_url_array.join(".")
      end
      #add adwords account name
      google_account.adwords_account_name = "Adwords account"
      #generate adwords campaign, adwords campaign group and call to action overlay
      adwords_campaign = if self.adwords_campaign_groups.present?
        self.adwords_campaign_groups.last.adwords_campaign
      else
        adc = AdwordsCampaign.create(name: "Adwords campaign", campaign_type: AdwordsCampaign.campaign_type.find_value("Video").value,
          campaign_subtype: AdwordsCampaign.campaign_subtype.find_value("Standard").value, networks_youtube_search: true,
          networks_youtube_videos: true, networks_include_video_partners: true,
          languages: "en", start_date: Time.now, end_date: nil,
          google_account_id: google_account.id, ready: ready)
        adc.name += " #{adc.id}"
        adc.save
        adc
      end
      if adwords_campaign.present? && !self.adwords_campaign_groups.present?
        adwords_campaign_group = AdwordsCampaignGroup.create(youtube_video_id: self.id,
        adwords_campaign_id: adwords_campaign.id, name: "Adwords campaign group",
          video_ad_format: AdwordsCampaignGroup.video_ad_format.find_value("In-stream ad").value, display_url: display_url.first(AdwordsCampaignGroup::DISPLAY_URL_LIMIT), final_url: final_url,
          ad_name: "Video ad", ready: ready, video_ad_url: self.url)
        adwords_campaign_group.name += " #{adwords_campaign_group.id}"
        adwords_campaign_group.ad_name += " #{adwords_campaign_group.id}"
        adwords_campaign_group.save
      end
      call_to_action_overlay = if self.call_to_action_overlay.present?
        self.call_to_action_overlay
      else
        CallToActionOverlay.new
      end
      call_to_action_overlay.headline = short_statement
      call_to_action_overlay.display_url = display_url.first(CallToActionOverlay::DISPLAY_URL_LIMIT)
      call_to_action_overlay.destination_url = final_url
      call_to_action_overlay.enabled_on_mobile = true
      call_to_action_overlay.ready = ready
      call_to_action_overlay.youtube_video_id = self.id
      call_to_action_overlay.save
      google_account.save
    end
  end

  def reset_post_production
    self.youtube_video_cards.each do |yvc|
      yvc.card_title = nil
      yvc.linked = false
      yvc.posting_time = nil
      yvc.save
    end
    self.adwords_campaign_groups.each do |acg|
      acg.name = "ACG " + rand(1..1000000).to_s
      acg.video_ad_url = ""
      acg.ready = false
      acg.linked = false
      acg.posting_time = nil
      acg.save
    end
    call_to_action_overlay = self.call_to_action_overlay
    if call_to_action_overlay.present?
      call_to_action_overlay.linked = false
      call_to_action_overlay.posting_time = nil
      call_to_action_overlay.save
    end
  end

  class << self

  	def by_id(id)
  		return all unless id.present?
  		where('youtube_videos.id in (?)', id.strip.split(",").map(&:to_i))
  	end

    def by_youtube_channel_id(youtube_channel_id)
      return all unless youtube_channel_id.present?
      where('youtube_videos.youtube_channel_id = ?', youtube_channel_id.strip)
    end

  	def by_title(title)
  		return all unless title.present?
  		where('LOWER(youtube_videos.title) LIKE ?', "%#{title.downcase.strip}%")
  	end

  	def by_youtube_channel_name(youtube_channel_name)
  		return all unless youtube_channel_name.present?
  		where('LOWER(youtube_channels.youtube_channel_name) LIKE ?', "%#{youtube_channel_name.downcase.strip}%")
  	end

  	def by_youtube_video_id(youtube_video_id)
  		return all unless youtube_video_id.present?
  		yvi = youtube_video_id.split("watch?v=").last.strip.downcase
  		where('LOWER(youtube_videos.youtube_video_id) LIKE ?', "%#{yvi}%")
  	end

  	def by_email(email)
  		return all unless email.present?
  		where('LOWER(email_accounts.email) LIKE ?', "%#{email.downcase.strip}%")
  	end

  	def by_tier(tier)
  		return all unless tier.present?

  		from = 0
  		to = 2499

  		case tier.to_i
  		when 1
  			return where('geobase_localities.population > 500000')
  		when 2
  			from = 100000
  			to = 500000
  		when 3
  			from = 50000
  			to = 99999
  		when 4
  			from = 25000
  			to = 49999
  		when 5
  			from = 10000
  			to = 24999
  		when 6
  			from = 5000
  			to = 9999
  		when 7
  			from = 2500
  			to = 4999
  		end

  		where('geobase_localities.population BETWEEN ? AND ?', from, to)
  	end

  	def by_country_id(country_id)
  		return all unless country_id.present?
  		where('geobase_regions.country_id = ? OR countries.id = ?', country_id, country_id)
  	end

  	def by_region_id(region_id)
  		return all unless region_id.present?
  		where('geobase_localities.primary_region_id = ? OR regions.id = ?', region_id, region_id)
  	end

  	def by_locality_id(locality_id)
  		return all unless locality_id.present?
  		where('geobase_localities.id = ?', locality_id)
  	end

  	def by_linked(linked)
  		return all unless linked.present?
  		if linked == true.to_s
  			where('youtube_videos.linked = TRUE')
  		else
  			where('youtube_videos.linked IS NOT TRUE')
  		end
  	end

  	def by_is_active(active)
  		return all unless active.present?

  		if active == true.to_s
  			where('youtube_videos.is_active = true')
  		else
  			where('youtube_videos.is_active IS NOT TRUE')
  		end
  	end

    def by_channel_is_active(active)
      return all unless active.present?
      if active == true.to_s
        where("youtube_channels.is_active = TRUE AND youtube_channels.blocked IS NOT TRUE")
      else
        where("youtube_channels.is_active IS NOT TRUE OR youtube_channels.blocked IS TRUE")
      end
    end

    def by_gmail_is_active(active)
      return all unless active.present?
      if active == true.to_s
        where("email_accounts.is_active IS TRUE AND email_accounts.deleted IS NOT TRUE")
      else
        where("email_accounts.is_active IS NOT TRUE OR email_accounts.deleted IS TRUE")
      end
    end

    def by_channel_is_verified(channel_is_verified)
      return all unless channel_is_verified.present?
      if channel_is_verified == true.to_s
        where("youtube_channels.is_verified_by_phone = TRUE")
      else
        where("youtube_channels.is_verified_by_phone IS NOT TRUE")
      end
    end

    def by_deleted(deleted)
      return all unless deleted.present?

      if deleted == true.to_s
        where('youtube_videos.deleted = TRUE')
      else
        where('youtube_videos.deleted IS NOT TRUE')
      end
    end

  	def by_ready(ready)
  		return all unless ready.present?
  		if ready == true.to_s
  			where('youtube_videos.ready = TRUE')
  		else
  			where('youtube_videos.ready IS NOT TRUE')
  		end
  	end

    def by_grab_statistics_succeded(grab_statistics_succeded)
      return all unless grab_statistics_succeded.present?
  		if grab_statistics_succeded == true.to_s
  			where('yt_statistics.grab_succeded = TRUE AND yt_statistics.current = TRUE')
  		else
  			where('yt_statistics.grab_succeded IS NOT TRUE AND yt_statistics.current = TRUE')
  		end
    end

    def by_grab_statistics_error_type(grab_statistics_error_type)
      return all unless grab_statistics_error_type.present?
  		where('yt_statistics.error_type = ? AND yt_statistics.current = TRUE', grab_statistics_error_type.to_i)
    end

    def by_processed(processed)
      return all unless processed.present?
  		if processed == true.to_s
  			where('yt_statistics.processed = TRUE AND yt_statistics.current = TRUE')
  		else
  			where('yt_statistics.processed IS NOT TRUE AND yt_statistics.current = TRUE')
  		end
    end

    def by_has_youtube_video_id(has_youtube_video_id)
      return all unless has_youtube_video_id.present?
      if has_youtube_video_id == true.to_s
  			where("youtube_videos.youtube_video_id IS NOT NULL AND youtube_videos.youtube_video_id <> ''")
  		else
  			where("(youtube_videos.youtube_video_id IS NULL OR youtube_videos.youtube_video_id = '')")
  		end
    end

    def by_posted_on_google_plus(posted_on_google_plus)
      return all unless posted_on_google_plus.present?
      if posted_on_google_plus == true.to_s
        where('youtube_videos.posted_on_google_plus = TRUE')
      else
        where('youtube_videos.posted_on_google_plus IS NOT TRUE')
      end
    end

  	def by_client_id(client_id)
  		return all unless client_id.present?
      if client_id.to_s == "7"
        where("youtube_channels.client_id = ?", client_id)
      else
        where("email_accounts.client_id = ?", client_id)
      end
  	end

    def by_bot_server_id(bot_server_id)
      return all unless bot_server_id.present?
      where("email_accounts.bot_server_id = ?", bot_server_id)
    end

  	def by_display_all(display_all)
  		if display_all.present?
  			return all
  		else
  			where("email_accounts.actual IS TRUE")
  		end
  	end

    def by_posted_annotations(posted)
      return all unless posted.present?
      if posted == true.to_s
        where("youtube_video_annotations.linked = TRUE AND youtube_video_annotations.ready = TRUE AND youtube_video_annotations.youtube_video_id IS NOT NULL")
      else
        where("youtube_video_annotations.linked IS NOT TRUE AND youtube_video_annotations.youtube_video_id IS NOT NULL")
      end
    end

    def by_posted_cards(posted)
      return all unless posted.present?
      if posted == true.to_s
        where("youtube_video_cards.linked = TRUE AND youtube_video_cards.ready = TRUE AND youtube_video_cards.youtube_video_id IS NOT NULL")
      else
        where("youtube_video_cards.linked IS NOT TRUE AND youtube_video_cards.youtube_video_id IS NOT NULL")
      end
    end

    def by_posted_call_to_action_overlays(posted)
      return all unless posted.present?
      if posted == true.to_s
        where("call_to_action_overlays.linked = TRUE AND call_to_action_overlays.ready = TRUE AND call_to_action_overlays.youtube_video_id IS NOT NULL")
      else
        where("call_to_action_overlays.linked IS NOT TRUE AND call_to_action_overlays.youtube_video_id IS NOT NULL")
      end
    end

    def by_last_event_time(table_name, field_name, last_time)
      return all if !(last_time.present? && field_name.present? && table_name.present?)
      where("#{table_name}.#{field_name} between ? AND current_timestamp", Time.now - last_time.to_i.hours)
    end

    def average_posting_time(last_time = nil, bot_server_id = nil, client_id = nil)
      if client_id.present?
        YoutubeVideo.joins(
            "LEFT OUTER JOIN youtube_channels ON youtube_channels.id = youtube_videos.youtube_channel_id
            LEFT OUTER JOIN google_accounts ON google_accounts.id = youtube_channels.google_account_id
            LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id
            LEFT OUTER JOIN clients ON clients.id = email_accounts.client_id"
          ).where("clients.id = ? AND youtube_videos.posting_time > 0 #{'AND youtube_videos.publication_date > ' + "'#{Time.now.utc - last_time.to_i.hours}'" if last_time.present?} #{'AND email_accounts.bot_server_id = ' + bot_server_id.to_s if bot_server_id.present?}", client_id).average("youtube_videos.posting_time").to_i
      else
        YoutubeVideo.joins(
            "LEFT OUTER JOIN youtube_channels ON youtube_channels.id = youtube_videos.youtube_channel_id
            LEFT OUTER JOIN google_accounts ON google_accounts.id = youtube_channels.google_account_id
            LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id"
          ).where("youtube_videos.posting_time > 0 #{'AND youtube_videos.publication_date > ' + "'#{Time.now.utc - last_time.to_i.hours}'" if last_time.present?} #{'AND email_accounts.bot_server_id = ' + bot_server_id.to_s if bot_server_id.present?}").average("youtube_videos.posting_time").to_i
      end
    end

    def average_google_plus_upload_time(last_time = nil, bot_server_id = nil, client_id = nil)
      if client_id.present?
        YoutubeVideo.joins(
            "LEFT OUTER JOIN youtube_channels ON youtube_channels.id = youtube_videos.youtube_channel_id
            LEFT OUTER JOIN google_accounts ON google_accounts.id = youtube_channels.google_account_id
            LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id
            LEFT OUTER JOIN clients ON clients.id = email_accounts.client_id"
          ).where("clients.id = ? AND youtube_videos.google_plus_upload_time > 0 #{'AND youtube_videos.posted_on_google_plus_at > ' + "'#{Time.now.utc - last_time.to_i.hours}'" if last_time.present?} #{'AND email_accounts.bot_server_id = ' + bot_server_id.to_s if bot_server_id.present?}", client_id).average("youtube_videos.google_plus_upload_time").to_i
      else
        YoutubeVideo.joins(
            "LEFT OUTER JOIN youtube_channels ON youtube_channels.id = youtube_videos.youtube_channel_id
            LEFT OUTER JOIN google_accounts ON google_accounts.id = youtube_channels.google_account_id
            LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id"
          ).where("youtube_videos.google_plus_upload_time > 0 #{'AND youtube_videos.posted_on_google_plus_at > ' + "'#{Time.now.utc - last_time.to_i.hours}'" if last_time.present?} #{'AND email_accounts.bot_server_id = ' + bot_server_id.to_s if bot_server_id.present?}").average("youtube_videos.google_plus_upload_time").to_i
      end
    end

    def yt_statistics_data(calc_method, field, client_id = nil)
      youtube_videos_join = "LEFT OUTER JOIN youtube_channels ON youtube_channels.id = youtube_videos.youtube_channel_id
      LEFT OUTER JOIN google_accounts ON google_accounts.id = youtube_channels.google_account_id
      LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id
      LEFT OUTER JOIN clients ON clients.id = email_accounts.client_id
      LEFT OUTER JOIN yt_statistics ON yt_statistics.resource_id = youtube_videos.id AND yt_statistics.resource_type = 'YoutubeVideo'"
      result = if client_id.present?
        YoutubeVideo.joins(youtube_videos_join).by_display_all(nil).where("clients.id = ? AND youtube_videos.is_active = TRUE AND yt_statistics.current = TRUE", client_id).send(calc_method, "yt_statistics.#{field}")
      else
        YoutubeVideo.joins(youtube_videos_join).by_display_all(nil).where("youtube_videos.is_active = TRUE AND yt_statistics.current = TRUE").send(calc_method, "yt_statistics.#{field}")
      end
  		if calc_method == 'average'
  			result.to_f.round(1)
  		else
  			result.to_i
  		end
    end
  end

  def update_adwords_campaign_groups_and_call_to_action_overlay
    youtube_setup = self.youtube_channel.google_account.email_account.try(:email_accounts_setup).try(:youtube_setup)
    if youtube_setup.present? && !youtube_setup.client.ignore_landing_pages && self.youtube_video_id.present? && !self.deleted && youtube_setup.present?
      if !self.call_to_action_overlay.present? && !self.youtube_video_cards.present? && youtube_setup.use_call_to_action_overlays
        self.generate_adwords_and_call_to_action_overlays(true)
      end
      self.adwords_campaign_groups.each do |acg|
        acg.video_ad_url = self.url
        acg.ready = true
        acg.save
      end
    end
  end

  def generate_search_phrases
    search_phrases = []
    current = 0
    100.times do
      current += 1
      search_phrases << YoutubeService.generate_youtube_video_title(self)
      break if search_phrases.compact.uniq.reject(&:blank?).size >= Setting.get_value_by_name("YoutubeVideo::SEARCH_PHRASES_LIMIT").to_i
    end
    search_phrases.compact.uniq.reject(&:blank?).each do |phrase|
      YoutubeVideoSearchPhrase.create(youtube_video_id: self.id, phrase: phrase)
    end
  end

	private
    def tags_length_validation
      keywords_str = self.tags.to_s.split(",").compact.map(&:strip).uniq{|e| e.mb_chars.downcase.to_s}.join(",")
      keywords_count = keywords_str.split(",").size
      limit = Setting.get_value_by_name("YoutubeVideo::TAGS_CHARS_LIMIT").to_i - (keywords_count - 1) * 2
      if keywords_str.size > limit
        errors.add(:tags, "is too long (maximum is #{limit} characters for #{keywords_count} tags)")
      end
    end

    def change_fields_to_update
      #remove spaces in tags
      self.tags = self.tags.to_s.split(",").compact.map(&:strip).uniq{|e| e.mb_chars.downcase.to_s}.join(",")
      if self.id.present? && self.is_active && self.youtube_video_id.present?
        fields_to_update_array = self.fields_to_update.to_s.split(',').collect(&:strip).uniq
        fields_to_update_array = fields_to_update_array + self.changed - %w(fields_to_update linked is_active deleted ready youtube_video_id publication_date posting_time posted_on_google_plus posted_on_google_plus_at google_plus_comment google_plus_upload_time yt_stat_json rotate_content_date)
        if fields_to_update_array.include?("thumbnail_updated_at")
          fields_to_update_array << "thumbnail"
          fields_to_update_array = fields_to_update_array.uniq - %w(thumbnail_file_name thumbnail_file_size thumbnail_updated_at)
        end
        if fields_to_update_array.include?("language_id")
          fields_to_update_array << "language"
          fields_to_update_array = fields_to_update_array.uniq - %w(language_id)
        end
        self.fields_to_update = fields_to_update_array.uniq.join(',')
        self.linked = false if fields_to_update.present?
      end
      self
    end
end
