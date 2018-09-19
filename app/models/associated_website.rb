class AssociatedWebsite < ActiveRecord::Base
  include Reversible
  extend Enumerize
  ASSOCIATION_METHODS = {"Placement of HTML-file on the server" => 1, "HTML Tag" => 2, "Domain Name Provider" => 3, "Google Analytics" => 4, "Google Tag Manager" => 5}
  enumerize :association_method, :in => ASSOCIATION_METHODS
  belongs_to :client_landing_page
  belongs_to :youtube_channel
  validates :client_landing_page_id, :youtube_channel_id, presence: true

  def acceptable_for_adding?
    [!linked, ready, client_landing_page.present?, client_landing_page.parked, client_landing_page.hosted, youtube_channel.is_verified_by_phone,  youtube_channel.youtube_channel_name.present?, youtube_channel.youtube_channel_id.present?, youtube_channel.channel_type.business?, youtube_channel.ready, youtube_channel.linked, youtube_channel.is_active].all?
  end

  def page_url
    client_landing_page.present? ? client_landing_page.page_url : ""
  end

  def json
    json_text = {}
    json_text[:id] = self.id
    json_text[:channel_id] = self.youtube_channel_id
    json_text[:youtube_channel_id] = self.youtube_channel.try(:youtube_channel_id)
    json_text[:website] = [self.client_landing_page.try(:subdomain), self.client_landing_page.try(:domain)].reject(&:empty?).join('.')
    json_text[:domain] = self.client_landing_page.try(:domain)
    json_text[:dns_record] = self.dns_record.to_s
    json_text[:method] = AssociatedWebsite.association_method.values.first
    json_text[:ready] = self.ready
    json_text[:linked] = self.linked
    json_text
  end

  def add_posting_time
    gaa = youtube_channel.google_account.google_account_activity
    if gaa.youtube_website_associate_start.present?
      if self.linked && self.updated_at > gaa.youtube_website_associate_start.last
        last_published_youtube_website_associate = AssociatedWebsite.joins("LEFT OUTER JOIN youtube_channels ON youtube_channels.id = associated_websites.youtube_channel_id").where("youtube_channels.google_account_id = ? AND associated_websites.linked IS TRUE AND associated_websites.updated_at > ? AND associated_websites.id <> ?", youtube_channel.google_account.id, gaa.youtube_website_associate_start.last, self.id).order("associated_websites.updated_at DESC").first
        starting_point = last_published_youtube_website_associate.present? ? last_published_youtube_website_associate.updated_at : gaa.youtube_website_associate_start.last
        time = Time.at(self.updated_at - starting_point).utc
        self.posting_time = time.hour*3600 + time.min*60 + time.sec if time.hour == 0
        self.save
      end
    end
  end

  def self.average_posting_time(last_time = nil, bot_server_id = nil, client_id = nil)
    if client_id.present?
      AssociatedWebsite.joins(
          "LEFT OUTER JOIN youtube_channels ON youtube_channels.id = associated_websites.youtube_channel_id
          LEFT OUTER JOIN google_accounts ON google_accounts.id = youtube_channels.google_account_id
          LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id
          LEFT OUTER JOIN clients ON clients.id = email_accounts.client_id"
        ).where("clients.id = ? AND associated_websites.posting_time > 0 AND associated_websites.linked IS TRUE #{'AND associated_websites.updated_at > ' + "'#{Time.now.utc - last_time.to_i.hours}'" if last_time.present?} #{'AND email_accounts.bot_server_id = ' + bot_server_id.to_s if bot_server_id.present?}", client_id).average("associated_websites.posting_time").to_i
    else
      AssociatedWebsite.joins(
          "LEFT OUTER JOIN youtube_channels ON youtube_channels.id = associated_websites.youtube_channel_id
          LEFT OUTER JOIN google_accounts ON google_accounts.id = youtube_channels.google_account_id
          LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id"
        ).where("associated_websites.posting_time > 0 AND associated_websites.linked IS TRUE #{'AND associated_websites.updated_at > ' + "'#{Time.now.utc - last_time.to_i.hours}'" if last_time.present?} #{'AND email_accounts.bot_server_id = ' + bot_server_id.to_s if bot_server_id.present?}").average("associated_websites.posting_time").to_i
    end
  end
end
