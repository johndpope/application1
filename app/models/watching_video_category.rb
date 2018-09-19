class WatchingVideoCategory < ActiveRecord::Base
  include Reversible
  has_and_belongs_to_many :google_account_activities
  validates :name, presence: true
	before_save :clean_up_phrases
  WATCHING_VIDEO_CATEGORIES_NUMBER = 4

	def clean_up_phrases
		self.phrases = self.phrases.to_s.split(",").collect(&:strip).uniq{|e| e.downcase}.join(",")
	end
end
