class FacebookAccount < ActiveRecord::Base
  include Reversible
  belongs_to :google_account
  belongs_to :phone
  has_one :social_account, as: :social_item, dependent: :destroy
  validates_uniqueness_of :google_account_id
  FACEBOOK_ACCOUNTS_PER_PHONE_LIMIT = 1
end
