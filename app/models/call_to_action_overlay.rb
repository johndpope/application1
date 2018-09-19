class CallToActionOverlay < ActiveRecord::Base
	include Reversible
	HEADLINE_LIMIT = 25
	# including 'http://' 42
	DISPLAY_URL_LIMIT = 35

	belongs_to :youtube_video
	validates_length_of :headline, :maximum => HEADLINE_LIMIT, allow_blank: false
	validates_length_of :display_url, :maximum => DISPLAY_URL_LIMIT
  validates_uniqueness_of :youtube_video_id
	validates :destination_url, presence: true
	validates :display_url, presence: true
	validates :destination_url, url: { allow_blank: false }

	def display_url_normalized
		url = self.display_url
		if url.blank?
			''
		else
			url = url unless url[/\Ahttp:\/\//] || url[/\Ahttps:\/\//]
			url.gsub!(' ', '%20')
			URI.parse(url).to_s
		end
	end

	def destination_url_normalized
		url = self.destination_url
		if url.blank?
			''
		else
			url = url unless url[/\Ahttp:\/\//] || url[/\Ahttps:\/\//]
			url.gsub!(' ', '%20')
			URI.parse(url).to_s
		end
	end

	def acceptable_for_adding?
		yc = self.youtube_video.youtube_channel
		google_account = self.youtube_video.youtube_channel.google_account
		has_posted_youtube_business_channel = (yc.channel_type == YoutubeChannel.channel_type.find_value(:business) && yc.linked && yc.is_active) ? true : false
		has_posted_adwords_campaign = false
		has_posted_adwords_campaign_group = false
		google_account.adwords_campaigns.each do |ac|
			has_posted_adwords_campaign = true if ac.ready && ac.linked
			ac.adwords_campaign_groups.each do |acg|
				has_posted_adwords_campaign_group = true if acg.ready && acg.linked
			end
		end
		[!yc.blocked, has_posted_youtube_business_channel, has_posted_adwords_campaign, has_posted_adwords_campaign_group, google_account.email_account.is_active, !google_account.email_account.deleted, google_account.adwords_account_name.present?, ready, !linked].all?
	end

	def json
		json_object = {}
		json_object =  JSON.parse(self.to_json)
		json_object["youtube_channel_url"] = self.youtube_video.youtube_channel.url
		json_object["youtube_video_url"] = self.youtube_video.url
		json_object["adwords_account_name"] = self.youtube_video.youtube_channel.google_account.adwords_account_name
		json_object
	end

  def add_posting_time
    gaa = youtube_video.youtube_channel.google_account.google_account_activity
    if gaa.call_to_action_overlay_add_start.present?
      if self.linked && self.updated_at > gaa.call_to_action_overlay_add_start.last
        last_published_call_to_action_overlay = CallToActionOverlay.joins("LEFT OUTER JOIN youtube_videos ON youtube_videos.id = call_to_action_overlays.youtube_video_id LEFT OUTER JOIN youtube_channels ON youtube_channels.id = youtube_videos.youtube_channel_id").where("youtube_channels.google_account_id = ? AND call_to_action_overlays.linked IS TRUE AND call_to_action_overlays.updated_at > ? AND call_to_action_overlays.id <> ?", youtube_video.youtube_channel.google_account.id, gaa.call_to_action_overlay_add_start.last, self.id).order("call_to_action_overlays.updated_at DESC").first
        starting_point = last_published_call_to_action_overlay.present? ? last_published_call_to_action_overlay.updated_at : gaa.call_to_action_overlay_add_start.last
        time = Time.at(self.updated_at - starting_point).utc
        self.posting_time = time.hour*3600 + time.min*60 + time.sec if time.hour == 0
        self.save
      end
    end
  end

  def self.average_posting_time(last_time = nil, bot_server_id = nil, client_id = nil)
    if client_id.present?
      CallToActionOverlay.joins(
          "LEFT OUTER JOIN youtube_videos ON youtube_videos.id = call_to_action_overlays.youtube_video_id
          LEFT OUTER JOIN youtube_channels ON youtube_channels.id = youtube_videos.youtube_channel_id
          LEFT OUTER JOIN google_accounts ON google_accounts.id = youtube_channels.google_account_id
          LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id
          LEFT OUTER JOIN clients ON clients.id = email_accounts.client_id"
        ).where("clients.id = ? AND call_to_action_overlays.posting_time > 0 AND call_to_action_overlays.linked IS TRUE #{'AND call_to_action_overlays.updated_at > ' + "'#{Time.now.utc - last_time.to_i.hours}'" if last_time.present?} #{'AND email_accounts.bot_server_id = ' + bot_server_id.to_s if bot_server_id.present?}", client_id).average("call_to_action_overlays.posting_time").to_i
    else
      CallToActionOverlay.joins(
          "LEFT OUTER JOIN youtube_videos ON youtube_videos.id = call_to_action_overlays.youtube_video_id
          LEFT OUTER JOIN youtube_channels ON youtube_channels.id = youtube_videos.youtube_channel_id
          LEFT OUTER JOIN google_accounts ON google_accounts.id = youtube_channels.google_account_id
          LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id"
        ).where("call_to_action_overlays.posting_time > 0 AND call_to_action_overlays.linked IS TRUE #{'AND call_to_action_overlays.updated_at > ' + "'#{Time.now.utc - last_time.to_i.hours}'" if last_time.present?} #{'AND email_accounts.bot_server_id = ' + bot_server_id.to_s if bot_server_id.present?}").average("call_to_action_overlays.posting_time").to_i
    end
  end
end
