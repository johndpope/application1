class ContactUsMailer < ActionMailer::Base
	default from: 'no-reply@echovideoblender.com'
	RECIPIENTS = Rails.env.development? ? 'zavorotnii@gmail.com' : 'zavorotnii@gmail.com, black3mamba@gmail.com, serghei.topor@gmail.com, admin@echoblender.com, alfred@echoblender.com, mike@echoblender.com, royce@echoblender.com, tmriordan@gmail.com'

	def notifications_email
    begin
  		mail(to: RECIPIENTS, subject: 'New notification through sandbox contact us form').deliver if RECIPIENTS.present?
    rescue
      Utils.pushbullet_broadcast("Something wrong with SMTP", "Something wrong with SMTP on no-reply@echovideoblender.com account. Please review!")
    end
	end
end
