class YoutubeVideoAnnotation < ActiveRecord::Base
	include Reversible

	TYPES = {
		'SpeechBubble' => 1,
		'Note' => 2,
		'Title' => 3,
		'Spotlight' => 4,
		'Label' => 5,
	}

	STYLES = {
		'Normal' => 1,
		'Impact' => 2
	}

	FONT_SIZES = [11, 13, 16, 28, 48, 72, 100]

	FONT_COLORS = {
		'Black' => 1,
		'White' => 2
	}

	# Add all backgrounds
	BACKGROUNDS = {
		'White' => 1,
		'Black' => 2
	}

	LINK_TYPES = {
		'Video' => 1,
		'Playlist' => 2,
		'Channel' => 3,
		'Google+' => 4,
		'Subscribe' => 5,
		'Crowfunding project' => 6,
		'Associated Website' => 7,
		'Merch' => 8,
	}

	DESCRIPTION_LIMIT = 1000

	extend Enumerize
	enumerize :annotation_type, :in => TYPES
	enumerize :style, :in => STYLES
	enumerize :font_color, :in => FONT_COLORS
	enumerize :background, :in => BACKGROUNDS
	enumerize :link_type, :in => LINK_TYPES

	belongs_to :youtube_video
	with_options :if => Proc.new{|obj| !(obj.is_a? YoutubeVideoAnnotationTemplate)} do |youtube_video_annotation|
		youtube_video_annotation.validates :youtube_video_id, :description, :presence => true
		youtube_video_annotation.validates_length_of :description, :maximum => DESCRIPTION_LIMIT
	end

	def start_time_to_time
		to_time(start_time)
	end

	def end_time_to_time
		to_time(end_time)
	end

	def link_start_time_to_time
		to_time(link_start_time)
	end

	def acceptable_for_adding?
		[youtube_video.youtube_video_id.present?, !youtube_video.youtube_channel.blocked, youtube_video.linked, youtube_video.is_active, youtube_video.ready, ready, !linked].all?
	end

	def json
		json_object = {}
		json_object = JSON.parse(self.to_json)
		json_object["start_time"] = start_time_to_time
		json_object["end_time"] = end_time_to_time
		json_object["link_start_time"] = link_start_time_to_time
		json_object["channel_url"] = self.youtube_video.youtube_channel.url
		json_object["video_url"] = self.youtube_video.url
		json_object["video_title"] = self.youtube_video.title
    json_object["youtube_channel_id"] = self.youtube_video.youtube_channel.id
    json_object["associated_website_id"] = self.youtube_video.youtube_channel.associated_websites.last.try(:id)
		json_object
	end

  def add_posting_time
    gaa = youtube_video.youtube_channel.google_account.google_account_activity
    if gaa.youtube_video_annotation_add_start.present?
      if self.linked && self.updated_at > gaa.youtube_video_annotation_add_start.last
        last_published_youtube_video_annotation = YoutubeVideoAnnotation.joins("LEFT OUTER JOIN youtube_videos ON youtube_videos.id = youtube_video_annotations.youtube_video_id LEFT OUTER JOIN youtube_channels ON youtube_channels.id = youtube_videos.youtube_channel_id").where("youtube_channels.google_account_id = ? AND youtube_video_annotations.linked IS TRUE AND youtube_video_annotations.updated_at > ? AND youtube_video_annotations.id <> ?", youtube_video.youtube_channel.google_account.id, gaa.youtube_video_annotation_add_start.last, self.id).order("youtube_video_annotations.updated_at DESC").first
        starting_point = last_published_youtube_video_annotation.present? ? last_published_youtube_video_annotation.updated_at : gaa.youtube_video_annotation_add_start.last
        time = Time.at(self.updated_at - starting_point).utc
        self.posting_time = time.hour*3600 + time.min*60 + time.sec if time.hour == 0
        self.save
      end
    end
  end

  def self.average_posting_time(last_time = nil, bot_server_id = nil, client_id = nil)
    if client_id.present?
      YoutubeVideoAnnotation.joins(
          "LEFT OUTER JOIN youtube_videos ON youtube_videos.id = youtube_video_annotations.youtube_video_id
          LEFT OUTER JOIN youtube_channels ON youtube_channels.id = youtube_videos.youtube_channel_id
          LEFT OUTER JOIN google_accounts ON google_accounts.id = youtube_channels.google_account_id
          LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id
          LEFT OUTER JOIN clients ON clients.id = email_accounts.client_id"
        ).where("clients.id = ? AND youtube_video_annotations.posting_time > 0 AND youtube_video_annotations.linked IS TRUE #{'AND youtube_video_annotations.updated_at > ' + "'#{Time.now.utc - last_time.to_i.hours}'" if last_time.present?} #{'AND email_accounts.bot_server_id = ' + bot_server_id.to_s if bot_server_id.present?}", client_id).average("youtube_video_annotations.posting_time").to_i
    else
      YoutubeVideoAnnotation.joins(
          "LEFT OUTER JOIN youtube_videos ON youtube_videos.id = youtube_video_annotations.youtube_video_id
          LEFT OUTER JOIN youtube_channels ON youtube_channels.id = youtube_videos.youtube_channel_id
          LEFT OUTER JOIN google_accounts ON google_accounts.id = youtube_channels.google_account_id
          LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id"
        ).where("youtube_video_annotations.posting_time > 0 AND youtube_video_annotations.linked IS TRUE #{'AND youtube_video_annotations.updated_at > ' + "'#{Time.now.utc - last_time.to_i.hours}'" if last_time.present?} #{'AND email_accounts.bot_server_id = ' + bot_server_id.to_s if bot_server_id.present?}").average("youtube_video_annotations.posting_time").to_i
    end
  end

	private
		def to_time(seconds)
			seconds.present? ? Time.at(seconds).utc.strftime("%H:%M:%S.#{0}") : ''
		end
end
