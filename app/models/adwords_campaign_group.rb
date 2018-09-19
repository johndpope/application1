class AdwordsCampaignGroup < ActiveRecord::Base
	include Reversible
	VIDEO_AD_FORMATS = {
		'In-stream ad' => 1,
		'In-display ad' => 2
	}
	NAME_LIMIT = 128
	HEADLINE_LIMIT = 25
	# including 'http://' 42
	DISPLAY_URL_LIMIT = 35
	DESCRIPTION_1_LIMIT, DESCRIPTION_2_LIMIT = 35
	AD_NAME_LIMIT = 235
	belongs_to :adwords_campaign
	belongs_to :youtube_video
	validates_length_of :name, :maximum => NAME_LIMIT, allow_blank: false
	validates_length_of :ad_name, :maximum => AD_NAME_LIMIT, allow_blank: false
	validates :video_ad_format, presence: true
	validates :adwords_campaign_id, presence: true
	validates :video_ad_url, url: { allow_blank: false }, if: :has_no_youtube_video?
	validates :display_url, presence: true, if: :is_in_stream_ad_format?
	validates :final_url, url: { allow_blank: false }, if: :is_in_stream_ad_format?
	validates :headline, :description_1, :description_2, presence: true, if: :is_in_display_ad_format?

	extend Enumerize
	enumerize :video_ad_format, :in => VIDEO_AD_FORMATS

	def has_no_youtube_video?
		!youtube_video_id.present?
	end

	def is_in_display_ad_format?
    self.video_ad_format == AdwordsCampaignGroup.video_ad_format.find_value('In-display ad')
  end

	def is_in_stream_ad_format?
		self.video_ad_format == AdwordsCampaignGroup.video_ad_format.find_value('In-stream ad')
	end

	def video_ad_url_normalized
		url = self.video_ad_url
		if url.blank?
			''
		else
			url = url unless url[/\Ahttp:\/\//] || url[/\Ahttps:\/\//]
			url.gsub!(' ', '%20')
			URI.parse(url).to_s
		end
	end

	def acceptable_for_adding?
		has_youtube_business_channel = false
		ga = self.adwords_campaign.google_account
		ga.youtube_channels.each do |yc|
			has_youtube_business_channel = true if yc.channel_type == YoutubeChannel.channel_type.find_value(:business) && yc.linked && yc.is_active && !yc.blocked
		end
		[youtube_video.present?, youtube_video.try(:youtube_video_id).present?, !youtube_video.try(:youtube_channel).try(:blocked), has_youtube_business_channel, ga.email_account.is_active, !ga.email_account.deleted, ga.adwords_account_name.present?, adwords_campaign.ready, adwords_campaign.linked, ready, !linked].all?
	end

	def json
		json_object = {}
		json_object =  JSON.parse(self.to_json)
		json_object["email_account_id"] = self.adwords_campaign.google_account.email_account.id
		json_object["adwords_campaign_name"] = self.adwords_campaign.name
		json_object["adwords_account_name"] = self.adwords_campaign.google_account.adwords_account_name
		json_object
	end

  def add_posting_time
    gaa = adwords_campaign.google_account.google_account_activity
    if gaa.adwords_campaign_group_add_start.present?
      if self.linked && self.updated_at > gaa.adwords_campaign_group_add_start.last
        last_published_adwords_campaign_group = AdwordsCampaignGroup.joins("LEFT OUTER JOIN adwords_campaigns ON adwords_campaigns.id = adwords_campaign_groups.adwords_campaign_id").where("adwords_campaigns.google_account_id = ? AND adwords_campaign_groups.linked IS TRUE AND adwords_campaign_groups.updated_at > ? AND adwords_campaign_groups.id <> ?", self.adwords_campaign.google_account_id, gaa.adwords_campaign_group_add_start.last, self.id).order("adwords_campaign_groups.updated_at DESC").first
        starting_point = last_published_adwords_campaign_group.present? ? last_published_adwords_campaign_group.updated_at : gaa.adwords_campaign_group_add_start.last
        time = Time.at(self.updated_at - starting_point).utc
        self.posting_time = time.hour*3600 + time.min*60 + time.sec if time.hour == 0
        self.save
      end
    end
  end

  def self.average_posting_time(last_time = nil, bot_server_id = nil, client_id = nil)
    if client_id.present?
      AdwordsCampaignGroup.joins(
          "LEFT OUTER JOIN adwords_campaigns ON adwords_campaigns.id = adwords_campaign_groups.adwords_campaign_id
          LEFT OUTER JOIN google_accounts ON google_accounts.id = adwords_campaigns.google_account_id
          LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id
          LEFT OUTER JOIN clients ON clients.id = email_accounts.client_id"
        ).where("clients.id = ? AND adwords_campaign_groups.posting_time > 0 AND adwords_campaign_groups.linked IS TRUE #{'AND adwords_campaign_groups.updated_at > ' + "'#{Time.now.utc - last_time.to_i.hours}'" if last_time.present?} #{'AND email_accounts.bot_server_id = ' + bot_server_id.to_s if bot_server_id.present?}", client_id).average("adwords_campaign_groups.posting_time").to_i
    else
      AdwordsCampaignGroup.joins(
          "LEFT OUTER JOIN adwords_campaigns ON adwords_campaigns.id = adwords_campaign_groups.adwords_campaign_id
          LEFT OUTER JOIN google_accounts ON google_accounts.id = adwords_campaigns.google_account_id
          LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id"
        ).where("adwords_campaign_groups.posting_time > 0 AND adwords_campaign_groups.linked IS TRUE #{'AND adwords_campaign_groups.updated_at > ' + "'#{Time.now.utc - last_time.to_i.hours}'" if last_time.present?} #{'AND email_accounts.bot_server_id = ' + bot_server_id.to_s if bot_server_id.present?}").average("adwords_campaign_groups.posting_time").to_i
    end
  end
end
