class GooglePlusAccount < ActiveRecord::Base
  include Reversible
  belongs_to :google_account
  belongs_to :youtube_channel
  validates_uniqueness_of :youtube_channel_id
  has_one :social_account, as: :social_item, dependent: :destroy
end
