class YtStatistic < ActiveRecord::Base
  belongs_to :resource, polymorphic: true
  ERROR_VIDEO_TYPES = {
    "This video has been removed for violating YouTube's Terms of Service" => 1,
		"This video has been removed by the user" => 2,
    "This video is unavailable" => 3,
    "This video is a duplicate of a previously uploaded video" => 4,
    "This video is no longer available because the YouTube account associated with this video has been terminated" => 5,
    "This video is no longer available due to a copyright claim" => 6,
    "This video is private" => 7
  }
  ERROR_CHANNEL_TYPES = {
    "This account has been terminated due to multiple or severe violations of YouTube's policy against spam, deceptive practices, and misleading content or other Terms of Service violations" => 8,
    "This account has been terminated for violating Google's Terms of Service" => 9,
    "This account has been terminated for violating YouTube's Community Guidelines" => 10,
    "This channel does not exist" => 12
  }
  ERROR_TYPES = ERROR_VIDEO_TYPES.merge(ERROR_CHANNEL_TYPES).merge({"Other" => 11})
  extend Enumerize
	enumerize :error_type, :in => ERROR_TYPES
end
