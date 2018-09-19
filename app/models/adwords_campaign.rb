class AdwordsCampaign < ActiveRecord::Base
	include Reversible

	TYPES = {
		'Search Netwok with Display Select' => 1,
		'Search Network Only' => 2,
		'Display Network Only' => 3,
		'Shopping' => 4,
		'Video' => 5,
		'Universal app compaign' => 6
	}
	SUBTYPES = {
		'Standard' => 1,
		'Mobile app installs' => 2,
		'Shopping' => 3,
	}

	LANGUAGES = {'all-languages' => 'All languages', 'ar' => 'Arabic', 'bg' => 'Bulgarian', 'ca' => 'Catalan',
		'zh_CN' => 'Chinese (simplified)', 'zh_TW' => 'Chinese (traditional)', 'hr' => 'Croatian', 'cs' => 'Czech',
		'da' => 'Danish', 'nl' => 'Dutch', 'en' => 'English', 'et' => 'Estonian', 'tl' => 'Filipino', 'fi' => 'Finnish',
		'fr' => 'French', 'de' => 'German', 'el' => 'Greek', 'iw' => 'Hebrew', 'hi' => 'Hindi', 'hu' => 'Hungarian',
		'is' => 'Icelandic', 'id' => 'Indonesian', 'it' => 'Italian', 'ja' => 'Japanese', 'ko' => 'Korean', 'lv' => 'Latvian',
		'lt' => 'Lithuanian', 'ms' => 'Malay', 'no' => 'Norwegian', 'fa' => 'Persian', 'pl' => 'Polish', 'pt' => 'Portuguese',
		'ro' => 'Romanian', 'ru' => 'Russian', 'sr' => 'Serbian', 'sk' => 'Slovak', 'sl' => 'Slovenian', 'es' => 'Spanish',
		'sv' => 'Swedish', 'th' => 'Thai', 'tr' => 'Turkish', 'uk' => 'Ukrainian', 'ur' => 'Urdu', 'vi' => 'Vietnamese'}

	NAME_LIMIT = 128

	belongs_to :google_account
	has_many :adwords_campaign_groups, dependent: :destroy
	validates_length_of :name, :maximum => NAME_LIMIT, allow_blank: false
	validates :languages, presence: true

	extend Enumerize
	enumerize :campaign_type, :in => TYPES
	enumerize :campaign_subtype, :in => SUBTYPES

	def acceptable_for_adding?
		has_youtube_business_channel = false
		self.google_account.youtube_channels.each do |yc|
			has_youtube_business_channel = true if yc.channel_type == YoutubeChannel.channel_type.find_value(:business) && yc.linked && yc.is_active && !yc.blocked
		end
		[has_youtube_business_channel, google_account.email_account.is_active, !google_account.email_account.deleted, google_account.adwords_account_name.present?, campaign_type.present?, name.present?, start_date.present?, ready, !linked].all?
	end

	def json
		json_object = {}
		json_object =  JSON.parse(self.to_json)
		json_object.delete("google_account_id")
		json_object["email_account_id"] = self.google_account.email_account.id
		json_object["adwords_account_name"] = self.google_account.adwords_account_name
		json_object["start_date"] = self.start_date.present? ? self.start_date.try(:strftime, "%b %e, %Y") : ""
		json_object["end_date"] = self.end_date.present? ? self.end_date.try(:strftime, "%b %e, %Y") : ""
		json_object
	end

  def add_posting_time
    gaa = google_account.google_account_activity
    if gaa.adwords_campaign_add_start.present?
      if self.linked && self.updated_at > gaa.adwords_campaign_add_start.last
        last_published_adwords_campaign = AdwordsCampaign.where("google_account_id = ? AND linked IS TRUE AND updated_at > ? AND id <> ?", self.google_account_id, gaa.adwords_campaign_add_start.last, self.id).order("updated_at DESC").first
        starting_point = last_published_adwords_campaign.present? ? last_published_adwords_campaign.updated_at : gaa.adwords_campaign_add_start.last
        time = Time.at(self.updated_at - starting_point).utc
        self.posting_time = time.hour*3600 + time.min*60 + time.sec if time.hour == 0
        self.save
      end
    end
  end

  def self.average_posting_time(last_time = nil, bot_server_id = nil, client_id = nil)
    if client_id.present?
      AdwordsCampaign.joins(
          "LEFT OUTER JOIN google_accounts ON google_accounts.id = adwords_campaigns.google_account_id
          LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id
          LEFT OUTER JOIN clients ON clients.id = email_accounts.client_id"
        ).where("clients.id = ? AND adwords_campaigns.posting_time > 0 AND adwords_campaigns.linked IS TRUE #{'AND adwords_campaigns.updated_at > ' + "'#{Time.now.utc - last_time.to_i.hours}'" if last_time.present?} #{'AND email_accounts.bot_server_id = ' + bot_server_id.to_s if bot_server_id.present?}", client_id).average("adwords_campaigns.posting_time").to_i
    else
      AdwordsCampaign.joins(
          "LEFT OUTER JOIN google_accounts ON google_accounts.id = adwords_campaigns.google_account_id
          LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id"
        ).where("adwords_campaigns.posting_time > 0 AND adwords_campaigns.linked IS TRUE #{'AND adwords_campaigns.updated_at > ' + "'#{Time.now.utc - last_time.to_i.hours}'" if last_time.present?} #{'AND email_accounts.bot_server_id = ' + bot_server_id.to_s if bot_server_id.present?}").average("adwords_campaigns.posting_time").to_i
    end
  end
end
