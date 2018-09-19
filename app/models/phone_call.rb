class PhoneCall < ActiveRecord::Base
  include Reversible
  belongs_to :phone, foreign_key: :phone_id
  belongs_to :admin_user, foreign_key: :admin_user_id
  validates :call_file_url, :phone_id, presence: :true
  after_create :send_notification

  def call_file_url
    if self[:call_file_url].present?
      Setting.get_value_by_name("Phone::ASTERISK_URL") + self[:call_file_url]
    end
  end

  class << self
    def by_id(id)
      return all unless id.present?
      where("id = ?", id)
    end

    def by_call_file_url(call_file_url)
      return all unless call_file_url.present?
      where("call_file_url = ?", call_file_url)
    end
  end

  private
    def send_notification
      Utils.pushbullet_broadcast("New phone call received", "Please go to http://#{Rails.configuration.routes_default_url_options[:host]}#{Rails.application.routes.url_helpers.phone_calls_path(id: self.id)} and enter sms code.")
    end
end
