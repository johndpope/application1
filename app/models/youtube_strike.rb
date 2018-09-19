class YoutubeStrike < ActiveRecord::Base
  include Reversible
  belongs_to :youtube_channel
  has_many :screenshots, as: :screenshotable, dependent: :destroy

  EMAIL_SCREENSHOT_PATH = "/out/screen/gmail_notification_strike/<username>.jpg"
  CHANNEL_SCREENSHOT_PATH = "/out/screen/youtube_channel_strike/<youtube_channel_id>.jpg"
  ATTENTION_CHANNEL_SCREENSHOT_PATH = "/out/screen/youtube_channel_strike/<youtube_channel_id>_attention.jpg"

  def save_screenshots
    bot_server_url = self.youtube_channel.try(:google_account).try(:email_account).try(:bot_server).try(:path) || Setting.get_value_by_name('EmailAccount::BOT_URL')
    email_image_url = bot_server_url + Setting.get_value_by_name('YoutubeStrike::EMAIL_SCREENSHOT_PATH').gsub('<username>', self.youtube_channel.google_account.email_account.email.gsub("@gmail.com", ""))
		channel_image_url = bot_server_url + Setting.get_value_by_name('YoutubeStrike::CHANNEL_SCREENSHOT_PATH').gsub('<youtube_channel_id>', self.youtube_channel.youtube_channel_id)
    attention_channel_image_url = bot_server_url + Setting.get_value_by_name('YoutubeStrike::ATTENTION_CHANNEL_SCREENSHOT_PATH').gsub('<youtube_channel_id>', self.youtube_channel.youtube_channel_id)
    [email_image_url, channel_image_url, attention_channel_image_url].each do |image_url|
  		begin
  			file = open(image_url)
  			screen = Screenshot.new
  			screen.image = file
  			extension = Rack::Mime::MIME_TYPES.invert[screen.image_content_type]
  			screen.image_file_name = File.basename(self.id.to_s)[0..-1] + extension
  			self.screenshots << screen
        file.close unless file.closed?
  			true
  		rescue
  			false
  		end
    end
	end
end
