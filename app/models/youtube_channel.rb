class YoutubeChannel < ActiveRecord::Base
  include Reversible
  include Workable
  SCREENSHOT_PATH = '/out/screen/youtube_channel/<id>.jpg'
  TAGS_LIMIT = 36
  TAGS_CHARS_LIMIT = 500
	#Youtube limit 101
	CHANNEL_NAME_LIMIT = 100
	#Youtube limit 1000
	CHANNEL_DESCRIPTION_LIMIT = 980
  SCREENSHOTS_LIMIT = 20
	CHANNEL_NAME_DELIMITERS = ["/", "-"]
  YOUTUBE_URL = 'https://www.youtube.com'
  SUBSCRIBE_PATH = '?sub_confirmation=1'
  CHANNEL_TYPES = { business: 1, personal: 2 }
  CATEGORIES =  { 'Product or Brand' => 1, 'Company, Institution or Organization' => 2, 'Arts, Entertaiment or Sports' => 3, 'Other' => 4 }
  BUSINESS_CHANNELS_PER_PHONE_LIMIT = 2
	BASE_YOUTUBE_VIDEO_THUMBNAIL_DIR = "/tmp/broadcaster/youtube_videos/thumbnails"
	CREDITS_PLACEHOLDER = '<CREDITS/>'
  extend Enumerize
  enumerize :category, :in => CATEGORIES
  enumerize :channel_type, :in => CHANNEL_TYPES, scope: true
	enumerize :all_videos_privacy, :in => YoutubeVideo::PRIVACY_LEVELS

  has_many :youtube_videos, dependent: :destroy
  has_many :youtube_strikes, dependent: :destroy
  has_many :youtube_channel_playlists, dependent: :destroy
  has_many :screenshots, as: :screenshotable, dependent: :destroy
  has_many :phone_usages, :as => :phone_usageable
  has_many :jobs, as: :resource, dependent: :destroy
  belongs_to :google_account, :foreign_key => :google_account_id
	has_one :email_account, through: :google_account
	has_one :client, through: :email_account
  has_many :client_landing_pages, through: :associated_websites
  has_many :associated_websites
  has_one :google_plus_account, dependent: :destroy
  has_many :yt_statistics, as: :resource, dependent: :destroy

  validates :google_account, presence: true
  validates :category, presence: true
  validates :youtube_channel_name, presence: true
  validates_length_of :youtube_channel_name, :maximum => CHANNEL_NAME_LIMIT
  validates_length_of :description, :maximum => CHANNEL_DESCRIPTION_LIMIT, :allow_blank => true
  #validates_length_of :keywords, :maximum => TAGS_CHARS_LIMIT, :allow_blank => true
  validate :keywords_length_validation
  validates :youtube_channel_id, uniqueness: true, allow_nil: true

  before_save :change_fields_to_update
  after_create :fill_fields_to_update
  after_save :create_google_plus_account

  attr_accessor :channel_icon
  attr_accessor :channel_art

  has_attached_file :channel_icon, :keep_old_files => true,
    path: ":rails_root/public/system/images/youtube_channel_icons/:id_partition/:style/:basename.:extension",
    url:  "/system/images/youtube_channel_icons/:id_partition/:style/:basename.:extension",
    styles: {thumb:"150x150>"}
  validates_attachment :channel_icon, allow_blank: true,
    content_type: {content_type: ['image/png','image/jpeg', 'image/gif', 'image/bmp']},
    size: {greater_than: 0.bytes, less_than: 2.megabytes}
  validates :channel_icon, dimensions: { minimum_width: 250, minimum_height: 250 }

  has_attached_file :channel_art, :keep_old_files => true,
    path: ":rails_root/public/system/images/youtube_channel_arts/:id_partition/:style/:basename.:extension",
    url:  "/system/images/youtube_channel_arts/:id_partition/:style/:basename.:extension",
    styles: { thumb: '150x150>' }
  validates_attachment :channel_art, allow_blank: true,
    content_type: { content_type: ['image/png','image/jpeg', 'image/gif', 'image/bmp'] },
    size: { greater_than: 0.bytes, less_than: 2.megabytes }
  validates :channel_art, dimensions: { minimum_width: 2048, minimum_height: 1152 }

  include YoutubeChannelArt

  work_queue :youtube_channel_creation, repeat_after: nil

  def display_name
  	"#{youtube_channel_name}"
  end

  def youtube_channel_creation_job_display_name
		"#{youtube_channel_name}"
	end

  def acceptable_for_all_videos_privacy?
    [!blocked, is_active, youtube_channel_id, channel_type.business?, ready, all_videos_privacy].all?
  end

  def acceptable_for_creation?
    [google_account.email_account.client.try(:is_active), !blocked, !linked, !is_active, !filled, !is_verified_by_phone, youtube_channel_name.present?, channel_type.business?, ready].all?
  end

  def acceptable_for_filling?
    [google_account.email_account.client.try(:is_active), !blocked, linked, is_active, !filled, youtube_channel_name.present?, youtube_channel_id.present?, channel_type.business?, ready].all?
  end

  def acceptable_for_verification?
    [google_account.email_account.client.try(:is_active), !blocked, linked, is_active, !is_verified_by_phone, youtube_channel_name.present?, youtube_channel_id.present?, channel_type.business?, ready].all?
  end

  def acceptable_for_recovery?
    last_recovery_inbox_email = RecoveryInboxEmail.where("email_account_id = ? and sender like '%youtube%'", google_account.email_account.id).order(date: :desc).first
    date_range_acceptable = if last_recovery_inbox_email.present? && last_recovery_inbox_email.try(:email_type).try(:value) == RecoveryInboxEmail.email_type.find_value("You have recently sent an appeal").value && last_recovery_inbox_email.date > Time.now - Setting.get_value_by_name("RecoveryInboxEmail::YOUTUBE_WAIT_FOR_RESULT_DAYS").to_i.days
      false
    else
      true
    end
    [date_range_acceptable, google_account.email_account.client.try(:is_active), blocked, youtube_channel_id.present?, channel_type.business?, google_account.email_account.is_active].all?
  end

	def can_be_verified_by_own_number?
		recovery_phone_id = self.google_account.email_account.recovery_phone_id
		recovery_phone_assigned = self.google_account.email_account.recovery_phone_assigned
    use_dids_for_channels = self.google_account.email_account.email_accounts_setup.present? ? self.google_account.email_account.email_accounts_setup.use_dids_for_channels : true
		can_be_verified = false
		if recovery_phone_id.present? && recovery_phone_assigned && use_dids_for_channels
			count = PhoneUsage.where("phone_id = ? AND action_type = ? and error_type IS NULL", recovery_phone_id, PhoneUsage.action_type.find_value("youtube business channel verification").value).size
			can_be_verified = true if count < Setting.get_value_by_name("YoutubeChannel::BUSINESS_CHANNELS_PER_PHONE_LIMIT").to_i
		end
		can_be_verified
	end

  def associated?
    associated = self.associated_websites.size > 0 ? true : nil
    self.associated_websites.each do |aw|
      associated = false if ![aw.linked, aw.ready].all?
    end
    associated
  end

  def save_screenshot
    bot_server_url = self.try(:google_account).try(:email_account).try(:bot_server).try(:path) || Setting.get_value_by_name('EmailAccount::BOT_URL')
    image_url = bot_server_url + Setting.get_value_by_name("YoutubeChannel::SCREENSHOT_PATH").gsub("<id>", self.id.to_s).downcase
    begin
      file = open(image_url)
      screen = Screenshot.new
      screen.image = file
      extension = Rack::Mime::MIME_TYPES.invert[screen.image_content_type]
      screen.image_file_name = File.basename(self.id.to_s)[0..-1] + extension
      self.screenshots << screen
      %x(curl -X GET "#{bot_server_url}/screen_rotate.php?path=youtube_channel&file=#{id}")
      screenshots_limit = Setting.get_value_by_name("YoutubeChannel::SCREENSHOTS_LIMIT").to_i
      if self.screenshots.size > screenshots_limit
        screenshots = self.screenshots.sort.to_a
        screenshots.pop
        screenshots = screenshots - screenshots.last(screenshots_limit)
        screenshots.each do |scr|
          scr.destroy if src.removable
        end
      end
      file.close unless file.closed?
      true
     rescue
      false
    end
  end

  def youtube_channel_name_with_email
    str = self.id.to_s
    str << " | " << self.youtube_channel_name if self.youtube_channel_name
    if self.google_account_id
      email = self.google_account.email_account.email
      str << " | " << email if email
    end
    str
  end

  def url()
    return "#{Setting.get_value_by_name("YoutubeChannel::YOUTUBE_URL")}/channel/#{self.youtube_channel_id}" if self.youtube_channel_id.present?
  end

  def subscribe_url
    "#{self.url}#{Setting.get_value_by_name("YoutubeChannel::SUBSCRIBE_PATH")}" if self.url.present?
  end

  def json
    json_object = {}
    json_object['id'] = id
    json_object['youtube_channel_name'] = youtube_channel_name
    # json_object[:url] = yc.url
    json_object['email'] = google_account.email_account.email
    json_object['password'] = google_account.email_account.password
    json_object['ip'] = google_account.email_account.ip_address.try(:address)
    json_object['youtube_channel_id'] = youtube_channel_id.present? ? youtube_channel_id : ""
    json_object['channel_type'] = channel_type
    json_object['category'] = category
    json_object['description'] = description.present? ? description.gsub("\r", "").squeeze(" ") : ''
    json_object['keywords'] = keywords.present? ? keywords : ''
    json_object['channel_links'] = channel_links.present? ? JSON.parse(channel_links)['links'] : []
    json_object['business_inquiries_email'] = business_inquiries_email.present? ? business_inquiries_email : ''
    json_object['overlay_google_plus'] = overlay_google_plus
    json_object['recommendations'] = recommendations
    json_object['subscriber_counts'] = subscriber_counts
    json_object['advertisements'] = advertisements
    json_object
  end

	#TODO: Urgently refactor !!!
	def generate_video(blended_video_id, ignore_associated_websites = false)
		tmp_youtube_video_thumbnail_file_path = File.join(BASE_YOUTUBE_VIDEO_THUMBNAIL_DIR, "#{SecureRandom.uuid}.png")
		ea = google_account.email_account
		email_accounts_setup = ea.email_accounts_setup
		youtube_setup = email_accounts_setup.try(:youtube_setup)
    client = email_accounts_setup.client
    blended_video = BlendedVideo.find_by_id(blended_video_id)
    source_video = blended_video.try(:source_video)
    product = source_video.try(:product)
    donor_client = product.try(:parent).try(:client)

    #do not permit create youtube video without associated website to channel
    has_associated_website = true
    if !ignore_associated_websites || !client.ignore_landing_pages
      has_associated_website = false if ClientLandingPage.joins("LEFT JOIN associated_websites ON associated_websites.client_landing_page_id = client_landing_pages.id").where("associated_websites.youtube_channel_id = ? AND associated_websites.ready = TRUE AND associated_websites.linked = TRUE AND client_landing_pages.product_id = ?", self.id, product.id).size == 0
    end

		if product.present? && email_accounts_setup.present? && email_accounts_setup.client.is_active && youtube_setup.present? && ea.is_active && self.is_active && has_associated_website
      client_landing_page = client.ignore_landing_pages ? nil : ClientLandingPage.joins("LEFT JOIN associated_websites ON associated_websites.client_landing_page_id = client_landing_pages.id").where("associated_websites.youtube_channel_id = ? AND associated_websites.ready = TRUE AND associated_websites.linked = TRUE AND client_landing_pages.product_id = ?", self.id, product.id).order("random()").first
			industry = client.industry
      donor_source_video = client.client_donor_source_videos.where(recipient_source_video_id: source_video.id).first.try(:source_video)
			##spin paragraphs
			#YoutubeService.spin_paragraphs(youtube_setup)
			##spin client descriptions
			# client.wordings.each { |wording| wording.generate_spintax(client.protected_words.to_s)}
			##spin product descriptions
			# product.wordings.each { |wording| wording.generate_spintax(product.protected_words.to_s)}
			##spin industry descriptions
			# industry.wordings.each { |wording| wording.generate_spintax(industry.name.to_s.split(",").collect(&:strip).uniq.join(","))} if industry.present?

			business_video_descriptors = youtube_setup.business_video_descriptor
			business_video_entities = youtube_setup.business_video_entity
			business_video_subjects = youtube_setup.business_video_subject

      business_video_title_pattern_arr = youtube_setup.business_video_title_patterns.shuffle.first.split(",")

			business_video_descriptors_sample = business_video_title_pattern_arr.include?("A") ? business_video_descriptors.to_a.sample.try(:camelize) : nil
			business_video_entities_sample = business_video_title_pattern_arr.include?("B") ? business_video_entities.to_a.sample.try(:camelize) : nil

      business_video_industry_component = if industry.nickname.present? && industry.industry_title_components.to_a.present?
        industry_title_groups = [industry.nickname, industry.try(:industry_title_components).to_a.sample.try(:camelize)]
        industry_groups_hash = {
          industry_title_groups[0] => 70,
          industry_title_groups[1] => 30,
        }
        industry_pickup = Pickup.new(industry_groups_hash)
        industry_group = industry_pickup.pick
      else
        industry.nickname || industry.try(:industry_title_components).to_a.sample.try(:camelize)
      end

      business_video_industry_sample = business_video_title_pattern_arr.include?("G") ? business_video_industry_component : nil

      if business_video_title_pattern_arr.include?("G") && business_video_entities_sample.present? && business_video_industry_sample.present?
        business_video_entities_sample = [business_video_industry_sample, business_video_entities_sample].join(" ")
        business_video_industry_sample = nil
      end

      business_video_subjects_sample = business_video_title_pattern_arr.include?("D") ? business_video_subjects.to_a.sample.try(:camelize) : nil

      subject_video_title_components = source_video.try(:subject_title_components).to_a + donor_source_video.try(:subject_title_components).to_a
      business_video_subject_videos_sample = business_video_title_pattern_arr.include?("E") ? subject_video_title_components.sample.try(:camelize) : nil

      product_title_components = product.try(:subject_title_components).to_a + product.try(:parent).try(:subject_title_components).to_a
      business_video_products_sample = business_video_title_pattern_arr.include?("C") ? product_title_components.sample.try(:camelize) : nil

      brand_title_component_sample = business_video_title_pattern_arr.include?("H") ? donor_client.try(:nickname) : nil

			#title
			youtube_video = YoutubeVideo.new
      youtube_video.blended_video_id = blended_video_id
			youtube_video.skip_thumbnail_presence_validation = true
			youtube_video.skip_video_presence_validation = true
			#assign google account
			youtube_video.youtube_channel_id = self.id

      video_name_delimiter_sample = YoutubeVideo::VIDEO_NAME_DELIMITERS.sample
      video_name_limit = Setting.get_value_by_name("YoutubeVideo::VIDEO_NAME_LIMIT").to_i

			locality_component = if ea.locality.present?
        locality_name_with_full_region_name = ea.locality.name_with_parent_region("@", "full")
        locality_name_with_abbr_region_name = ea.locality.name_with_parent_region(" ", "abbr")
        if [business_video_descriptors_sample, business_video_entities_sample, business_video_products_sample, locality_name_with_full_region_name, business_video_subject_videos_sample, business_video_subjects_sample, business_video_industry_sample].compact.join(video_name_delimiter_sample).strip.size <= video_name_limit && locality_name_with_full_region_name.split("@").uniq.size == 2
				  [locality_name_with_full_region_name.split("@").join(" "), locality_name_with_abbr_region_name].shuffle.first
        elsif [business_video_descriptors_sample, business_video_entities_sample, business_video_products_sample, locality_name_with_abbr_region_name, business_video_subject_videos_sample, business_video_subjects_sample, business_video_industry_sample].compact.shuffle.join(video_name_delimiter_sample).strip.size <= video_name_limit
          [locality_name_with_abbr_region_name, ea.locality.name_with_parent_region(" ", "")].shuffle.first
        else
          ea.locality.name_with_parent_region(" ", "")
        end
			else
				ea.region.name
			end
      video_title = [business_video_descriptors_sample, brand_title_component_sample, business_video_industry_sample, business_video_entities_sample, business_video_products_sample, locality_component, business_video_subject_videos_sample, business_video_subjects_sample].compact
      if video_title.shuffle.join(video_name_delimiter_sample).strip.size > video_name_limit
        video_title = [brand_title_component_sample, business_video_industry_sample, business_video_entities_sample, business_video_products_sample, locality_component, business_video_subject_videos_sample, business_video_subjects_sample].compact
        if video_title.shuffle.join(video_name_delimiter_sample).strip.size > video_name_limit
          video_title = [brand_title_component_sample, business_video_industry_sample, business_video_entities_sample, business_video_products_sample, locality_component, business_video_subject_videos_sample].compact
          if video_title.shuffle.join(video_name_delimiter_sample).strip.size > video_name_limit
            video_title = [brand_title_component_sample, business_video_industry_sample, business_video_entities_sample, business_video_products_sample, locality_component, business_video_subjects_sample].compact
            if video_title.shuffle.join(video_name_delimiter_sample).strip.size > video_name_limit
              video_title = [brand_title_component_sample, business_video_industry_sample, business_video_entities_sample, business_video_products_sample, locality_component].compact
              if video_title.shuffle.join(video_name_delimiter_sample).strip.size > video_name_limit
                video_title = [brand_title_component_sample, business_video_industry_sample, business_video_entities_sample, locality_component].compact
                if video_title.shuffle.join(video_name_delimiter_sample).strip.size > video_name_limit
                  video_title = [brand_title_component_sample, business_video_entities_sample, locality_component].compact
                  if video_title.shuffle.join(video_name_delimiter_sample).strip.size > video_name_limit
                    video_title = [business_video_entities_sample, locality_component].compact
                  end
                end
              end
            end
          end
        end
      end
			youtube_video.title = youtube_setup.business_video_title_components_shuffle ? video_title.shuffle.join(video_name_delimiter_sample).strip.first(video_name_limit) : video_title.join(video_name_delimiter_sample).strip.first(video_name_limit)

			youtube_video.save!

			#keywords
			business_video_tags = []
      youtube_video_tags_limit = Setting.get_value_by_name("YoutubeVideo::TAGS_LIMIT").to_i
      youtube_video_tags_chars_limit = Setting.get_value_by_name("YoutubeVideo::TAGS_CHARS_LIMIT").to_i
      youtube_video_tag_size_limit = Setting.get_value_by_name("YoutubeVideo::TAG_SIZE_LIMIT").to_i

      tag_groups_size = 7
      tag_groups_size -= 1 unless source_video.try(:tag_list).to_a.present?
      tag_groups_size -= 1 unless youtube_setup.other_business_video_tag_list.present?
      tag_groups_size -= 1 unless industry.tag_list.present?
      tag_groups_size -= 1 unless donor_client.try(:tag_list).present?
      each_tag_part_size = youtube_video_tags_limit / tag_groups_size
      business_video_tags << client.tag_list.reject{|t| t.size >= youtube_video_tag_size_limit}.sample(each_tag_part_size)
      business_video_tags << product.tag_list_with_parent.reject{|t| t.size >= youtube_video_tag_size_limit}.sample(each_tag_part_size)
      business_video_tags << donor_client.tag_list.reject{|t| t.size >= youtube_video_tag_size_limit}.sample(each_tag_part_size) if donor_client.try(:tag_list).present?
      business_video_tags << industry.tag_list.reject{|t| t.size >= youtube_video_tag_size_limit}.sample(each_tag_part_size) if industry.tag_list.present?
      business_video_tags << (source_video.try(:tag_list) + donor_source_video.try(:tag_list)).to_a.reject{|t| t.size >= youtube_video_tag_size_limit}.sample(each_tag_part_size) if source_video.try(:tag_list).to_a.present? || donor_source_video.try(:tag_list).to_a.present?
      business_video_tags << youtube_setup.other_business_video_tag_list.reject{|t| t.size >= youtube_video_tag_size_limit}.sample(each_tag_part_size) if youtube_setup.other_business_video_tag_list.present?
			# business_video_tag_groups = youtube_setup.business_video_tags_paragraphs
			# if business_video_tag_groups.size > 0
			# 	business_video_tag_groups.each do |bvtg|
			# 		business_video_tags << bvtg.body.split(",").sample(Setting.get_value_by_name("YoutubeVideo::TAGS_LIMIT").to_i/(business_video_tag_groups.size + 1))
			# 	end
			# end
      geo_tags = []
      geo_tags << ea.try(:locality).try(:name) if ea.try(:locality).try(:name).present?
      geo_tags << ea.try(:region).try(:name) if ea.try(:region).try(:name).present?
      geo_tags << ea.try(:locality).try(:primary_region).try(:name) if ea.try(:locality).try(:primary_region).try(:name).present?
			geo_tags << ea.try(:locality).try(:nicknames).try(:split, "<sep/>") if ea.try(:locality).try(:nicknames).present?
			geo_tags << ea.try(:region).try(:nicknames).try(:split, "<sep/>") if ea.try(:region).try(:nicknames).present?
			geo_tags << ea.try(:locality).try(:code).try(:split, "<sep/>") if ea.try(:locality).try(:code).present?
			geo_tags << ea.try(:locality).try(:primary_region).try(:code).try(:split, "<sep/>") if ea.try(:locality).try(:primary_region).try(:code).present?
			geo_tags << ea.try(:locality).try(:primary_region).try(:nicknames).try(:split, "<sep/>") if ea.try(:locality).try(:primary_region).try(:nicknames).present?
			geo_tags << ea.try(:region).try(:code).try(:split, "<sep/>") if ea.try(:region).try(:code).present?
      geo_tags << ea.try(:locality).try(:landmarks).try(:pluck, :name) if ea.try(:locality).try(:landmarks).present?
      geo_tags << ea.try(:region).try(:landmarks).try(:pluck, :name) if ea.try(:region).try(:landmarks).present?
      geo_tags << ea.try(:locality).try(:primary_region).try(:landmarks).try(:pluck, :name) if ea.try(:locality).try(:primary_region).try(:landmarks).present?

      geo_tags.flatten!
      geo_tags.map(&:strip!)
      locality_name_tag = geo_tags.first
      geo_tags.reject!{|t| t.size >= youtube_video_tag_size_limit}
      geo_tags.shuffle!

      business_video_tags << geo_tags.sample(youtube_video_tags_limit - business_video_tags.flatten.size)
			business_video_tags.flatten!
      business_video_tags = business_video_tags.compact.map(&:strip).uniq{|e| e.mb_chars.downcase.to_s}.shuffle
      #force to add name of the locality as tag
      business_video_tags.insert(0, locality_name_tag) if locality_name_tag.present?
      keywords = business_video_tags.uniq{|e| e.mb_chars.downcase.to_s}.join(",")
      keywords = keywords.split(",").join("\" \"").truncate(youtube_video_tags_chars_limit - 2, separator: /\s/).split("\" \"").join(",")
      if keywords.include?("...")
        keywords_array = keywords.split(",")
        keywords_array.pop
        keywords = keywords_array.join(",")
      end
      youtube_video.tags = keywords.split(",").reject{|t| t.size >= youtube_video_tag_size_limit}.shuffle.join(",")

			#description
			youtube_video.description = ""
			business_video_description_array = []
			# business_video_description_array << client.description_wording("long_description").try(:spintax).try(:unspin)
			# business_video_description_array << product.description_wording_with_parent("long_description").try(:spintax).try(:unspin)
			# business_video_description_array << industry.description_wording("long_description").try(:spintax).try(:unspin) if industry.present?
      business_video_description_array << client.description_wording(["long_description", "short_description"].shuffle.first).try(:source).try(:strip)
      if donor_client.present?
        donor_client_description = donor_client.description_wording(["long_description", "short_description"].shuffle.first).try(:source).try(:strip)
        business_video_description_array << donor_client_description if donor_client_description.present?
      end
      business_video_description_array << product.description_wording_with_parent(["long_description", "short_description"].shuffle.first).try(:source).try(:strip)
      business_video_description_array << industry.description_wording(["long_description", "short_description"].shuffle.first).try(:source).try(:strip) if industry.present?
      business_video_description_array << (source_video.try(:description_wording, "long_description").try(:source).try(:strip) || donor_source_video.try(:description_wording, "long_description").try(:source).try(:strip)) if source_video.try(:description_wording, "long_description").try(:source).present? || donor_source_video.try(:description_wording, "long_description").try(:source).present?
      business_video_description_array << youtube_setup.description_wording("long_description").try(:source).try(:strip)
      business_video_description_array << "\n" + TextChunk.where(chunk_type: 'client_landing_page_action').order('random()').first.value.try(:strip) + " " + client_landing_page.page_url + " .\n" if youtube_setup.use_landing_page_link_in_youtube_video_description && client_landing_page.present?
      if youtube_setup.social_links_in_youtube_video_description.to_i > 0
        parts = []
        parts << TextChunk.where(chunk_type: 'blog_action').order('random()').first.value.try(:strip) + " " + client.blog_url if client.blog_url.present?
        parts << TextChunk.where(chunk_type: 'google_plus_action').order('random()').first.value.try(:strip) + " " + client.google_plus_url if client.google_plus_url.present?
        parts << TextChunk.where(chunk_type: 'youtube_action').order('random()').first.value.try(:strip) + " " + client.youtube_url if client.youtube_url.present?
        parts << TextChunk.where(chunk_type: 'facebook_action').order('random()').first.value.try(:strip) + " " + client.facebook_url if client.facebook_url.present?
        parts << TextChunk.where(chunk_type: 'twitter_action').order('random()').first.value.try(:strip) + " " + client.twitter_url if client.twitter_url.present?
        parts << TextChunk.where(chunk_type: 'linkedin_action').order('random()').first.value.try(:strip) + " " + client.linkedin_url if client.linkedin_url.present?
        parts << TextChunk.where(chunk_type: 'instagram_action').order('random()').first.value.try(:strip) + " " + client.instagram_url if client.instagram_url.present?
        parts << TextChunk.where(chunk_type: 'pinterest_action').order('random()').first.value.try(:strip) + " " + client.pinterest_url if client.pinterest_url.present?
        parts.shuffle!
        parts = parts.first(youtube_setup.social_links_in_youtube_video_description.to_i)
        business_video_description_array << "\n" + parts.join(" .\n") + ". \n"
      end

			location_type = ""
			location_id = if ea.locality.present?
				location_type = ea.try(:locality).try(:class).try(:name)
				ea.locality.id
			else
				location_type = ea.try(:region).try(:class).try(:name)
				ea.try(:region).try(:id)
			end
			location_wording = Wording.where("resource_id = ? AND resource_type= ? AND name = ?", location_id, location_type, 'long_description').order("random()").first
      if !location_wording.present? && ea.locality.present? && ea.locality.neighbors.present?
        location_wording = Wording.where("resource_id in (?) AND resource_type= ? AND name = ?", ea.locality.neighbors.map(&:id), location_type, 'long_description').order("random()").first
      end
			if location_wording.present?
				# location_wording.generate_spintax(location_wording.resource.try(:protected_words).to_s)
				# business_video_description_array << location_wording.spintax.unspin
        business_video_description_array << location_wording.source.try(:strip)
			end

			#credits link
			#TODO: Fix route path error occuring when option Rails.application.routes.default_url_options[:host] is on
			#Temporary solution is to use Rails.configuration.routes_default_url_options[:host]
      credits_part = "\n" + [TextChunk.where(chunk_type: 'credits_action').order('random()').first.try(:value).to_s.try(:strip), "#{Rails.configuration.routes_default_url_options[:host]}#{Rails.application.routes.url_helpers.public_credits_youtube_video_path(youtube_video)}"].join(' ') + " .\n"
      business_video_description_array = business_video_description_array.reject(&:blank?)
      business_video_description_array.shuffle!
      business_video_description_array.insert([0,1,2].shuffle.first, credits_part)
      # business_video_description_array << youtube_setup.business_video_description(spin: true)

      video_description_limit = Setting.get_value_by_name("YoutubeVideo::VIDEO_DESCRIPTION_LIMIT").to_i
			if business_video_description_array.present?
        total_characters_limit = video_description_limit
        business_video_description_array_size = business_video_description_array.size
        paragraph_limit = total_characters_limit / business_video_description_array_size
        business_video_description_array.reverse!
        youtube_video.description = business_video_description_array.collect do |x|
          s = x
          init_sentences_count = Utils.smart_sentences_count(s)
          sentences_count = init_sentences_count
          while sentences_count > 0 && paragraph_limit < s.size do
            sentences_count -= 1
            s = Utils.smart_sentences_truncate(s, sentences_count)
          end
          s = Utils.smart_sentences_truncate(x, 1).truncate(paragraph_limit, separator: /\s/) if sentences_count == 0 && Utils.smart_sentences_truncate(x, 1).size > paragraph_limit
          business_video_description_array_size -= 1
          total_characters_limit = total_characters_limit - s.size
          paragraph_limit = total_characters_limit / business_video_description_array_size if business_video_description_array_size > 0

					#Exception Encoding::CompatibilityError: incompatible character encodings: UTF-8 and ASCII-8BIT sometime raises.
					#Temporary solution is to apply .force_encoding('UTF-8') for the spinned string
					s.force_encoding('UTF-8')
        end.reject(&:blank?).reverse.join(" ").strip.first(video_description_limit)
			end

      youtube_video.description = youtube_video.description.gsub("\n \n", "\n").gsub(/[\r\n]+/, "\n").gsub(/[\n\r]+/, "\n").gsub(/[\n]+/, "\n").strip.first(video_description_limit)

      #add keywords to the end of description
      # description_tags = []
      # description_tags << business_video_tags
      # # if business_video_tag_groups.size > 0
      # #   business_video_tag_groups.each do |bvtg|
      # #     description_tags << bvtg.body.split(",")
      # #   end
      # # end
      # description_tags << geo_tags
      # description_tags.flatten!
      # description_tags.map(&:strip!)
      # description_tags.uniq!
      #
      # if description_tags.present?
      #   keywords_bridge = TextChunk.where(chunk_type: "keywords_bridge").order("random()").first.try(:value)
      #   youtube_video.description = [youtube_video.description + "\n", keywords_bridge, description_tags.shuffle.join(", ")].reject(&:blank?).join(" ").truncate(video_description_limit, separator: /\s/, omission: "...")
      #   if youtube_video.description.include?("...") && youtube_video.description.include?(keywords_bridge)
      #     description_array = youtube_video.description.split(",")
      #     description_array.pop if description_array.size > 1
      #     youtube_video.description = description_array.join(",") + "."
      #   end
      # end
			# youtube_video.description = youtube_video.description.first(video_description_limit)
      # youtube_video.description = youtube_video.description.first(youtube_video.description.size - 1) if youtube_video.description.last(2) == ".."

			#category random()
			youtube_video.category = YoutubeVideo.category.find_value(YoutubeVideo.category.values.sample).value
			#put some default values about category, 3d. etc.
			youtube_video.privacy_level = YoutubeVideo.privacy_level.find_value("Public").value
			youtube_video.allow_comments = YoutubeVideo.allow_comments.find_value("All").value
			youtube_video.license = YoutubeVideo.license.find_value("Standard Youtube License").value
			youtube_video.syndication = YoutubeVideo.syndication.find_value("Everywhere").value
			youtube_video.video_3d = YoutubeVideo.video_3d.find_value("No preference").value
			youtube_video.language = Language.find_by_name("English")
			youtube_video.allow_embedding = true
			youtube_video.show_ratings = true
			youtube_video.notify_subscribers = true
			youtube_video.is_duplicate = false
			youtube_video.age_restriction = false
			youtube_video.show_statistics = true

			youtube_video.linked = false
			youtube_video.is_active = false

      short_statements = []
      short_statements = Wording.select(:source).where("resource_id = ? AND resource_type = 'SourceVideo' AND name = ?", source_video.id, 'short_statement').order("random()").map(&:source)
      short_statements = Wording.select(:source).where("resource_id = ? AND resource_type = 'SourceVideo' AND name = ?", donor_source_video.id, 'short_statement').order("random()").map(&:source) if !short_statements.present? && donor_source_video.present?
      short_statements = Wording.select(:source).where("resource_id = ? AND resource_type = 'Product' AND name = ?", source_video.product.id, 'short_statement').order("random()").map(&:source) unless short_statements.present?
      short_statements = Wording.select(:source).where("resource_id = ? AND resource_type = 'Product' AND name = ?", donor_source_video.product.id, 'short_statement').order("random()").map(&:source) if !short_statements.present? && donor_source_video.try(:product).present?
      if short_statements.present? && client_landing_page.present?
        youtube_video.google_plus_comment = short_statements.first + " " + client_landing_page.page_url
      end

			if youtube_video.save
        duration = youtube_video.duration
        if youtube_video.youtube_channel.associated_websites.present?
          if youtube_setup.use_youtube_video_cards && youtube_setup.use_call_to_action_overlays
            youtube_video.generate_youtube_video_cards(true) if [true, false].shuffle.first
          else
            youtube_video.generate_youtube_video_cards(true) if youtube_setup.use_youtube_video_cards
          end
        end

				google_account_activity = ea.email_item.google_account_activity
				google_account_activity.linked = false
				google_account_activity.save
				youtube_video.save!
				youtube_video
			else
				nil
			end
		else
			raise "Email Account with ID #{ea.id} is not active. Probably it was blocked by Google. Please check it" unless ea.is_active
			raise "Youtube Channel with ID #{self.id} is not active. Probably it was blocked by Google. Please check it" unless self.is_active
			raise "Youtube Channel with ID #{self.id} doesn't have any associated web site" unless has_associated_website
			raise "Email Account with ID #{ea.id} doesn't have relation with Email Accounts Setup" unless email_accounts_setup.present?
			raise "Source Video with ID #{source_video.id} doesn't have relation with Product" unless product.present?
      raise "Client with ID #{email_accounts_setup.client.id} is not active." if email_accounts_setup.present? && !email_accounts_setup.client.is_active
		end
		#return youtube video if Successfully created
	end

  class << self

    def by_id(id)
      return all unless id.present?
      where("youtube_channels.id in (?)", id.strip.split(",").map(&:to_i))
    end

    def by_youtube_channel_name(youtube_channel_name)
      return all unless youtube_channel_name.present?
      where("LOWER(youtube_channels.youtube_channel_name) LIKE ?", "%#{youtube_channel_name.downcase.strip}%")
    end

    def by_youtube_channel_id(youtube_channel_id)
      return all unless youtube_channel_id.present?
      yci = youtube_channel_id.gsub("#{Setting.get_value_by_name("YoutubeChannel::YOUTUBE_URL")}/channel/", '').strip.downcase
      where("LOWER(youtube_channels.youtube_channel_id) LIKE ?", "%#{yci}%")
    end

    def by_email(email)
      return all unless email.present?
      where("LOWER(email_accounts.email) LIKE ?", "%#{email.downcase.strip}%")
    end

    def by_tier(tier)
      return all unless tier.present?
      from = 0
      to = 2499
      case tier.to_i
        when 1
          return where("geobase_localities.population > 500000")
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
      where("geobase_localities.population BETWEEN ? AND ?", from, to)
    end

    def by_country_id(country_id)
      return all unless country_id.present?
      where("geobase_regions.country_id = ? OR countries.id = ?", country_id, country_id)
    end

    def by_region_id(region_id)
      return all unless region_id.present?
      where("geobase_localities.primary_region_id = ? OR regions.id = ?", region_id, region_id)
    end

    def by_locality_id(locality_id)
      return all unless locality_id.present?
      where("geobase_localities.id = ?", locality_id)
    end

    def by_linked(linked)
      return all unless linked.present?
      if linked == true.to_s
        where("youtube_channels.linked = TRUE")
      else
        where("youtube_channels.linked IS NOT TRUE")
      end
    end

    def by_filled(filled)
      return all unless filled.present?
      if filled == true.to_s
        where("youtube_channels.filled = TRUE")
      else
        where("youtube_channels.filled IS NOT TRUE")
      end
    end

    def by_is_active(active)
      return all unless active.present?
      if active == true.to_s
        where("youtube_channels.is_active = TRUE")
      else
        where("youtube_channels.is_active IS NOT TRUE")
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

    def by_is_verified_by_phone(is_verified_by_phone)
      return all unless is_verified_by_phone.present?
      if is_verified_by_phone == true.to_s
        where("youtube_channels.is_verified_by_phone = TRUE")
      else
        where("youtube_channels.is_verified_by_phone IS NOT TRUE")
      end
    end

    def by_ready(ready)
      return all unless ready.present?
      if ready == true.to_s
        where('youtube_channels.ready = TRUE')
      else
        where('youtube_channels.ready IS NOT TRUE')
      end
    end

    def by_blocked(blocked)
      return all unless blocked.present?

      if blocked == true.to_s
        where('youtube_channels.blocked = TRUE')
      else
        where('youtube_channels.blocked IS NOT TRUE')
      end
    end

    def by_created_by_phone(created_by_phone)
      return all unless created_by_phone.present?
      if created_by_phone == true.to_s
        where("phone_usages.sms_code IS NOT NULL AND phone_usages.sms_code <> '' AND phone_usages.action_type = ?", PhoneUsage.action_type.find_value("youtube business channel creation").value)
      end
    end

    def by_channel_type(channel_type)
      return all unless channel_type.present?
      where("youtube_channels.channel_type = ?", channel_type.to_i)
    end

    def by_all_videos_privacy(all_videos_privacy)
      return all unless all_videos_privacy.present?
      where("youtube_channels.all_videos_privacy = ?", all_videos_privacy.to_i)
    end

    def by_client_id(client_id)
      return all unless client_id.present?
      if client_id.to_s == "7"
        where("youtube_channels.client_id = ?", client_id)
      else
        where("email_accounts.client_id = ?", client_id)
      end
    end

    def by_strike(strike)
      return all unless strike.present?
      where("youtube_channels.strike = ?", strike.to_i)
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

    def by_associated_websites(associated)
      return all unless associated.present?
      if associated == true.to_s
        where("associated_websites.linked = TRUE AND associated_websites.ready = TRUE")
      else
        where("associated_websites.linked IS NOT TRUE OR associated_websites.ready IS NOT TRUE")
      end
    end

    def by_has_duplicate_videos(has_duplicate_videos)
      return all unless has_duplicate_videos.present?
      if has_duplicate_videos == true.to_s
        where("yt_statistics.current = TRUE AND yt_statistics.duplicate_videos = TRUE")
      else
        where("yt_statistics.current = TRUE AND yt_statistics.duplicate_videos IS NOT TRUE")
      end
    end

    def by_last_event_time(table_name, field_name, last_time)
      return all if !(last_time.present? && field_name.present? && table_name.present?)
      where("#{table_name}.#{field_name} between ? AND current_timestamp", Time.now - last_time.to_i.hours)
    end

    def average_posting_time(last_time = nil, bot_server_id = nil, client_id = nil)
      if client_id.present?
        YoutubeChannel.joins(
            "LEFT OUTER JOIN google_accounts ON google_accounts.id = youtube_channels.google_account_id
            LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id
            LEFT OUTER JOIN clients ON clients.id = email_accounts.client_id"
          ).where("clients.id = ? AND youtube_channels.is_active = TRUE AND youtube_channels.channel_type = ? AND youtube_channels.posting_time > 0 #{'AND youtube_channels.publication_date > ' + "'#{Time.now.utc - last_time.to_i.hours}'" if last_time.present?} #{'AND email_accounts.bot_server_id = ' + bot_server_id.to_s if bot_server_id.present?}", client_id, YoutubeChannel.channel_type.find_value(:business).value).average("youtube_channels.posting_time").to_i
      else
        YoutubeChannel.joins(
            "LEFT OUTER JOIN google_accounts ON google_accounts.id = youtube_channels.google_account_id
            LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id"
          ).where("youtube_channels.is_active = TRUE AND youtube_channels.channel_type = ? AND youtube_channels.posting_time > 0 #{'AND youtube_channels.publication_date > ' + "'#{Time.now.utc - last_time.to_i.hours}'" if last_time.present?} #{'AND email_accounts.bot_server_id = ' + bot_server_id.to_s if bot_server_id.present?}", YoutubeChannel.channel_type.find_value(:business).value).average("youtube_channels.posting_time").to_i
      end
    end

    def yt_statistics_data(calc_method, field, client_id = nil)
      youtube_channels_join = "LEFT OUTER JOIN google_accounts ON google_accounts.id = youtube_channels.google_account_id
          LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id
          LEFT OUTER JOIN clients ON clients.id = email_accounts.client_id
          LEFT OUTER JOIN yt_statistics ON yt_statistics.resource_id = youtube_channels.id AND yt_statistics.resource_type = 'YoutubeChannel'"
      result = if client_id.present?
        YoutubeChannel.joins(youtube_channels_join).by_display_all(nil).where("clients.id = ? AND youtube_channels.is_active = TRUE AND youtube_channels.channel_type = ? AND yt_statistics.current = TRUE", client_id, YoutubeChannel.channel_type.find_value(:business).value).send(calc_method, "yt_statistics.#{field}")
      else
        YoutubeChannel.joins(youtube_channels_join).by_display_all(nil).where("youtube_channels.is_active = TRUE AND youtube_channels.channel_type = ? AND yt_statistics.current = TRUE", YoutubeChannel.channel_type.find_value(:business).value).send(calc_method, "yt_statistics.#{field}")
      end
			if calc_method == 'average'
				result.to_f.round(1)
			else
				result.to_i
			end
    end
  end

  private
    def keywords_length_validation
      keywords_str = self.keywords.to_s.split(",").compact.map(&:strip).uniq{|e| e.mb_chars.downcase.to_s}.join(",")
      keywords_count = keywords_str.split(",").size
      limit = Setting.get_value_by_name("YoutubeChannel::TAGS_CHARS_LIMIT").to_i - (keywords_count - 1) * 2
      if keywords_str.size > limit
        errors.add(:keywords, "is too long (maximum is #{limit} characters for #{keywords_count} keywords)")
      end
    end

    def change_fields_to_update
      #remove spaces in keywords
      self.keywords = self.keywords.to_s.split(",").compact.map(&:strip).uniq{|e| e.mb_chars.downcase.to_s}.join(",")
      if self.id.present? && self.is_active && self.youtube_channel_id.present?
        fields_to_update_array = self.fields_to_update.to_s.split(',').collect(&:strip).uniq
        fields_to_update_array = fields_to_update_array + self.changed - %w(fields_to_update linked is_active blocked ready filled is_verified_by_phone youtube_channel_id publication_date filling_date thumbnails_enabled phone_number notes channel_icon_applied channel_art_applied posting_time strike all_videos_privacy client_id previous_google_account_id)
        if fields_to_update_array.include?("channel_icon_updated_at")
          fields_to_update_array << "channel_icon"
          fields_to_update_array = fields_to_update_array.uniq - %w(channel_icon_file_name channel_icon_file_size channel_icon_updated_at)
        end
        if fields_to_update_array.include?("channel_art_updated_at")
          fields_to_update_array << "channel_art"
          fields_to_update_array = fields_to_update_array.uniq - %w(channel_art_file_name channel_art_file_size channel_art_updated_at)
        end
        self.fields_to_update = fields_to_update_array.uniq.join(',')
        self.filled = false if fields_to_update.present?
      end
      self
    end

    def fill_fields_to_update
      json_all = self.json
      json_all["channel_icon_url"] = !self.channel_icon.blank? ? URI::escape(url + self.channel_icon.url(:original), '[]') : ''
      json_all["channel_art_url"] =  !self.channel_art.blank? ? URI::escape(url + self.channel_art.url(:original), '[]') : ''
      self.fields_to_update = (json_all.keys - %w(id channel_type ip email password is_active is_verified_by_phone linked blocked filled youtube_channel_name youtube_channel_id posting_time strike all_videos_privacy client_id previous_google_account_id)).join(",")
      self.save
    end

    def create_google_plus_account
      if [self.is_active, self.linked, self.ready, self.channel_type.business?, !self.google_plus_account.present?].all?
        g_plus_account = GooglePlusAccount.new(google_account: self.google_account, youtube_channel: self)
        g_plus_account.build_social_account(is_active:true, account_type: SocialAccount::ACCOUNT_TYPES[:business])
        g_plus_account.save
      end
    end
end
