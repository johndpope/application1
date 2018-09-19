class YoutubeVideoCard < ActiveRecord::Base
	include Reversible

	TYPES = {
		'Video or Playlist' => 1,
		'Channel' => 2,
		'Link' => 3
    # 'Donation' => 4,
    # 'Poll' => 5
	}

	CUSTOM_MESSAGE_LIMIT = 30
	TEASER_TEXT_LIMIT = 30
	CARD_TITLE_LIMIT = 50
  CALL_TO_ACTION_LIMIT = 30

	extend Enumerize
	enumerize :card_type, :in => TYPES

	belongs_to :youtube_video
	attr_accessor :card_image

  has_attached_file :card_image, :keep_old_files => true,
    path: ":rails_root/public/system/images/youtube_video_card_images/:id_partition/:style/:basename.:extension",
    url:  "/system/images/youtube_video_card_images/:id_partition/:style/:basename.:extension",
    styles: {thumb:"150x150>"}
  validates_attachment :card_image, content_type: {content_type: ['image/png','image/jpeg', 'image/gif', 'image/bmp']},
    size: {greater_than: 0.bytes, less_than: 2.megabytes}
  validates :card_image, dimensions: { minimum_width: 250, minimum_height: 250 }

	with_options :if => Proc.new{|obj| !(obj.is_a? YoutubeVideoCardTemplate)} do |youtube_video_card|
		youtube_video_card.validates :youtube_video_id, :card_type, :presence => true
		youtube_video_card.validates :url, url: { allow_blank: false }
	end

  with_options :if => Proc.new{|obj| !(obj.is_a? YoutubeVideoCardTemplate) && obj.card_type == YoutubeVideoCard.card_type.find_value("Channel")} do |youtube_video_card|
    youtube_video_card.validates_length_of :teaser_text, :maximum => TEASER_TEXT_LIMIT, :allow_blank => false
    youtube_video_card.validates_length_of :custom_message, :maximum => CUSTOM_MESSAGE_LIMIT, :allow_blank => false
  end

  with_options :if => Proc.new{|obj| !(obj.is_a? YoutubeVideoCardTemplate) && obj.card_type == YoutubeVideoCard.card_type.find_value("Link")} do |youtube_video_card|
    # youtube_video_card.validates_length_of :card_title, :maximum => CARD_TITLE_LIMIT, :allow_blank => true
    youtube_video_card.validates_length_of :teaser_text, :maximum => TEASER_TEXT_LIMIT, :allow_blank => false
    youtube_video_card.validates_length_of :call_to_action, :maximum => CALL_TO_ACTION_LIMIT, :allow_blank => false
    #youtube_video_card.validates_attachment_presence :card_image
  end

  def start_time_to_time
		to_time(start_time)
	end

	def normalized_url
		@url = self.url
		if @url.blank?
			''
		else
			@url = @url unless @url[/\Ahttp:\/\//] || @url[/\Ahttps:\/\//]
			@url.gsub!(' ', '%20')
			URI.parse(@url).to_s
		end
	end

	def acceptable_for_adding?
		[youtube_video.youtube_video_id.present?, !youtube_video.youtube_channel.blocked, youtube_video.linked, youtube_video.is_active, youtube_video.ready, ready, !linked].all?
	end

	def json
		json_object = {}
		json_object =  JSON.parse(self.to_json)
		json_object["start_time"] = self.start_time.to_i
		json_object["channel_url"] = self.youtube_video.youtube_channel.url
		json_object["video_url"] = self.youtube_video.url
		json_object["video_title"] = self.youtube_video.title
		json_object
	end

  def add_posting_time
    gaa = youtube_video.youtube_channel.google_account.google_account_activity
    if gaa.youtube_video_card_add_start.present?
      if self.linked && self.updated_at > gaa.youtube_video_card_add_start.last
        last_published_youtube_video_card = YoutubeVideoCard.joins("LEFT OUTER JOIN youtube_videos ON youtube_videos.id = youtube_video_cards.youtube_video_id LEFT OUTER JOIN youtube_channels ON youtube_channels.id = youtube_videos.youtube_channel_id").where("youtube_channels.google_account_id = ? AND youtube_video_cards.linked IS TRUE AND youtube_video_cards.updated_at > ? AND youtube_video_cards.id <> ?", youtube_video.youtube_channel.google_account.id, gaa.youtube_video_card_add_start.last, self.id).order("youtube_video_cards.updated_at DESC").first
        starting_point = last_published_youtube_video_card.present? ? last_published_youtube_video_card.updated_at : gaa.youtube_video_card_add_start.last
        time = Time.at(self.updated_at - starting_point).utc
        self.posting_time = time.hour*3600 + time.min*60 + time.sec if time.hour == 0
        self.save
      end
    end
  end

  def self.average_posting_time(last_time = nil, bot_server_id = nil, client_id = nil)
    if client_id.present?
      YoutubeVideoCard.joins(
          "LEFT OUTER JOIN youtube_videos ON youtube_videos.id = youtube_video_cards.youtube_video_id
          LEFT OUTER JOIN youtube_channels ON youtube_channels.id = youtube_videos.youtube_channel_id
          LEFT OUTER JOIN google_accounts ON google_accounts.id = youtube_channels.google_account_id
          LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id
          LEFT OUTER JOIN clients ON clients.id = email_accounts.client_id"
        ).where("clients.id = ? AND youtube_video_cards.posting_time > 0 AND youtube_video_cards.linked IS TRUE #{'AND youtube_video_cards.updated_at > ' + "'#{Time.now.utc - last_time.to_i.hours}'" if last_time.present?} #{'AND email_accounts.bot_server_id = ' + bot_server_id.to_s if bot_server_id.present?}", client_id).average("youtube_video_cards.posting_time").to_i
    else
      YoutubeVideoCard.joins(
          "LEFT OUTER JOIN youtube_videos ON youtube_videos.id = youtube_video_cards.youtube_video_id
          LEFT OUTER JOIN youtube_channels ON youtube_channels.id = youtube_videos.youtube_channel_id
          LEFT OUTER JOIN google_accounts ON google_accounts.id = youtube_channels.google_account_id
          LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id"
        ).where("youtube_video_cards.posting_time > 0 AND youtube_video_cards.linked IS TRUE #{'AND youtube_video_cards.updated_at > ' + "'#{Time.now.utc - last_time.to_i.hours}'" if last_time.present?} #{'AND email_accounts.bot_server_id = ' + bot_server_id.to_s if bot_server_id.present?}").average("youtube_video_cards.posting_time").to_i
    end
  end

  private
    def to_time(seconds)
      seconds.present? ? Time.at(seconds).utc.strftime("%H:%M:%S.#{0}") : ''
    end
end
