class YoutubeVideoSearchPhrase < ActiveRecord::Base
  include Reversible
  belongs_to :youtube_video
  belongs_to :email_account
  has_many :youtube_video_search_ranks, dependent: :destroy
  validates :phrase, presence: true

  def json
    {"id" => self.id, "phrase" => self.phrase}
  end
end
