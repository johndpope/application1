class YoutubeVideoSearchRank < ActiveRecord::Base
  SEARCH_TYPES = {google: 1, youtube: 2}
  RESULT_TYPES = {regular: 1, videos_box: 2, images_box: 3}
  extend Enumerize
	enumerize :search_type, in: SEARCH_TYPES
  enumerize :result_type, in: RESULT_TYPES

  belongs_to :youtube_video_search_phrase
  RANK_CHECK_FREQUENCY_DAYS = 30
  RANK_CHECK_FIRST_TIME_DELAY_DAYS = 3

  attr_accessor :screenshot
  has_attached_file :screenshot,
    path: ":rails_root/public/system/images/youtube_video_search_ranks/:id_partition/:style/:basename.:extension",
    url:  "/system/images/youtube_video_search_ranks/:id_partition/:style/:basename.:extension",
    styles: {thumb:"150x150>"}
  validates_attachment :screenshot,
    content_type: {content_type: ['image/png','image/jpeg', 'image/gif', 'image/bmp']},
    size: {greater_than: 0.bytes, less_than: 10.megabytes}

  def client
    self.youtube_video_search_phrase.try(:youtube_video).try(:youtube_channel).try(:google_account).try(:email_account).try(:client)
  end

  class << self
		def by_id(id)
			return all unless id.present?
			where("youtube_video_search_ranks.id = ?", id.strip)
		end

    def by_email_account_id(email_account_id)
      return all unless email_account_id.present?
			where("email_accounts.id = ? OR youtube_video_search_phrases.email_account_id = ?", email_account_id.to_i, email_account_id.to_i)
    end

    def by_page(page_number)
      return all unless page_number.present?
			where("youtube_video_search_ranks.page = ?", page_number.to_i)
    end

    def by_search_type(search_type)
      return all unless search_type.present?
      where("youtube_video_search_ranks.search_type = ?", search_type.to_i)
    end

    def by_result_type(result_type)
      return all unless result_type.present?
      where("youtube_video_search_ranks.result_type = ?", result_type.to_i)
    end

    def by_youtube_video_id(youtube_video_id)
  		return all unless youtube_video_id.present?
  		yvi = youtube_video_id.split("watch?v=").last.strip.downcase
      if yvi.to_i.to_s.size == yvi.size
        where('youtube_videos.id = ?', yvi.to_i)
      else
        where('LOWER(youtube_videos.youtube_video_id) LIKE ?', "%#{yvi}%")
      end
    end
  end
end
