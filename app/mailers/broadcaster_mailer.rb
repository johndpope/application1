class BroadcasterMailer < ActionMailer::Base
	default from: 'no-reply@echovideoblender.com'
	RECIPIENTS = Rails.env.development? ? 'zavorotnii@gmail.com' : Setting.get_value_by_name("Utils::EMAIL_RECEIVERS")

	def new_blocked_gmail_accounts
    begin
		  mail(to: RECIPIENTS, subject: 'New blocked gmail accounts!').deliver if RECIPIENTS.present?
    rescue
      Utils.pushbullet_broadcast("Something wrong with SMTP", "Something wrong with SMTP on no-reply@echovideoblender.com account. Please review!")
    end
	end

  def db_storage_alert
    begin
      mail(to: RECIPIENTS, subject: 'Database storage alert!').deliver if RECIPIENTS.present?
    rescue
      Utils.pushbullet_broadcast("Something wrong with SMTP", "Something wrong with SMTP on no-reply@echovideoblender.com account. Please review!")
    end
  end

  def nas_storage_alert
    begin
      mail(to: RECIPIENTS, subject: 'NAS storage alert!').deliver if RECIPIENTS.present?
    rescue
      Utils.pushbullet_broadcast("Something wrong with SMTP", "Something wrong with SMTP on no-reply@echovideoblender.com account. Please review!")
    end
  end

  def new_blocked_youtube_channel(youtube_channel_id = nil)
    begin
      @youtube_channel_id = youtube_channel_id
      mail(to: RECIPIENTS, subject: 'New blocked youtube channel!').deliver if RECIPIENTS.present?
    rescue
      Utils.pushbullet_broadcast("Something wrong with SMTP", "Something wrong with SMTP on no-reply@echovideoblender.com account. Please review!")
    end
  end

  def new_blocked_youtube_video(youtube_video_id)
    begin
      @youtube_video_id = youtube_video_id
      mail(to: RECIPIENTS, subject: 'New blocked youtube video!').deliver if RECIPIENTS.present?
    rescue
      Utils.pushbullet_broadcast("Something wrong with SMTP", "Something wrong with SMTP on no-reply@echovideoblender.com account. Please review!")
    end
  end

  def new_youtube_channel_strike(youtube_channel_id = nil)
    begin
      @youtube_channel_id = youtube_channel_id
      mail(to: RECIPIENTS, subject: 'New youtube channel strike!').deliver if RECIPIENTS.present?
    rescue
      Utils.pushbullet_broadcast("Something wrong with SMTP", "Something wrong with SMTP on no-reply@echovideoblender.com account. Please review!")
    end
  end

  def zenno_kill(bot_server_name, killed)
    begin
      @bot_server_name = bot_server_name
      @killed = killed
      subject = killed ? "Successfully killed Zenno!" : "Failed to kill Zenno!"
      mail(to: RECIPIENTS, subject: subject).deliver if RECIPIENTS.present?
    rescue
      Utils.pushbullet_broadcast("Something wrong with SMTP", "Something wrong with SMTP on no-reply@echovideoblender.com account. Please review!")
    end
  end

  def custom_mail(receivers, subject, body)
    begin
      @body = body
      mail_receivers = Rails.env.development? ? 'zavorotnii@gmail.com' : receivers
      mail(to: mail_receivers, subject: subject, body: body, content_type: 'text/html; charset=UTF-8').deliver
    rescue
      Utils.pushbullet_broadcast("Something wrong with SMTP", "Something wrong with SMTP on no-reply@echovideoblender.com account. Please review!")
    end
  end
end
