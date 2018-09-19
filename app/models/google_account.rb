require 'google/api_client'

class GoogleAccount < ActiveRecord::Base
  include Reversible
  GOOGLE_STATUSES =  {:accessible=>1, :wrong_credentials=>2, :disabled_by_google=>3, :should_pass_verification_in_google=>4, :got_captcha=>5}
  ACCOUNT_CATEGORIES = {:business=>1, :personal=>2}
  ERROR_TYPES = {
    "click next button" => 1, "click sign in button" => 2, "disabled / fill the form" => 3,
    "don't get locked out / add phone or recovery email" => 4, "sorry, google doesn't recognize that email" => 5,
    "email or password you entered is incorrect" => 6, "white screen" => 7, "enter capcha(old style)" => 8,
    "provide a phone number, we'll send a verification code" => 9, "cookies disabled" => 10, "youtube as logged in user" => 11,
    "youtube as not logged user" => 12, "gmail as logged user" => 13, "gmail as unlogged user" => 14,
    "google search as logged user" => 15, "please re-enter your password" => 16, "other" => 17
  }
	ADWORDS_ACCOUNT_NAME_LIMIT = 30
  extend Enumerize
  enumerize :google_status, :in=> GOOGLE_STATUSES
  enumerize :account_type, :in=>{:broadcast_account=>1, :technical_account=>2, :test_account=>3}
  enumerize :account_category, :in=> ACCOUNT_CATEGORIES
  enumerize :error_type, :in=> ERROR_TYPES

  has_one :email_account, as: :email_item, dependent: :destroy

  has_many :google_plus_accounts, dependent: :destroy
  has_one :facebook_account, dependent: :destroy
  has_one :google_api_project, dependent: :destroy
  has_one :google_account_activity, dependent: :destroy
  has_many :youtube_channels, dependent: :destroy
	has_many :adwords_campaigns, dependent: :destroy
  belongs_to :google_api_client, foreign_key: :google_api_client_id
  belongs_to :client, foreign_key: :client_id
  belongs_to :locality, foreign_key: :locality_id, class_name: 'Geobase::Locality'

  accepts_nested_attributes_for :google_account_activity

  validates :email, presence: true
	validates_length_of :adwords_account_name, maximum: ADWORDS_ACCOUNT_NAME_LIMIT, allow_blank: true

  def display_name
    email
  end

  def get_google_api_client()
      client = Google::APIClient.new(:application_name=>Rails.application.config.google_api[:application_name], :application_version=>Rails.application.config.google_api[:application_version])
      client.authorization.client_id = self.google_api_client.client_id
      client.authorization.client_secret = self.google_api_client.client_secret
      client.authorization.scope = Rails.application.config.google_api[:scopes]
      client.authorization.refresh_token = self.refresh_token
      return client
  end

  def fetch_access_token!()
      client = get_google_api_client
      client.authorization.fetch_access_token!
      return client.authorization.access_token
  end

  def youtube_channel()
    return youtube_channels.empty? ? nil : self.youtube_channels.first()
  end

  def self.active_broadcast_accounts()
    GoogleAccount.where({google_status: 1, account_type: 1, is_active: true}).count
  end

  def self.statistics()
    JSON.parse(ActiveRecord::Base.connection.execute('SELECT google_account_statistics_json() AS result')[0]['result'])
  end
end
