class YoutubeChannelPlaylist < ActiveRecord::Base
  include Reversible
  belongs_to :youtube_channel
  has_many :youtube_videos, through: :youtube_channel

  def url()
    return "#{Setting.get_value_by_name("YoutubeChannel::YOUTUBE_URL")}/watch?v=#{self.youtube_list_id}"
  end
end
