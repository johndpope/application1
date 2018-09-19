module EmailService
  NEW_RECOVERY_EMAILS_LIMIT = 10
  class << self
    def check_recovery_inbox_emails
      email_account_ids = EmailAccount.select(:id).joins('LEFT OUTER JOIN google_accounts ON email_accounts.email_item_id = google_accounts.id LEFT OUTER JOIN google_account_activities ON google_accounts.id = google_account_activities.google_account_id').by_account_type(EmailAccount.account_type.find_value(:operational).value).where("email_accounts.is_active = TRUE OR (email_accounts.is_active IS NOT TRUE AND email_accounts.actual IS TRUE)").pluck(:id)
      email_account_ids.each do |email_account_id|
        EmailService.delay_retrieve_emails(email_account_id, 1)
      end
    end

    def retrieve_recovery_inbox_emails(email_account)
      if Setting.get_value_by_name("RecoveryInboxEmail::READ_EMAILS_ENABLED").to_s == "true"
        imap = EmailService.init_recovery_email(email_account.recovery_email, email_account.recovery_email_password)
        emails = []
        count = email_account.recovery_inbox_emails.present? ? Setting.get_value_by_name("EmailService::NEW_RECOVERY_EMAILS_LIMIT").to_i : 10000
        inbox = begin
          imap.find(:what => :last, :count => count, :order => :asc)
        rescue
          []
        end
        sent = begin
          imap.find(:mailbox => 'Отправленные', :what => :last, :count => count, :order => :asc)
        rescue
          begin
            imap.find(:mailbox => 'Inbox', :what => :last, :count => count, :order => :asc)
          rescue
            []
          end
        end
        emails = inbox + sent
        # emails << imap.find(:what => :last, :count => count, :order => :asc, :keys => ['from', 'google'])
        # emails << imap.find(:what => :last, :count => count, :order => :asc, :keys => ['body', 'google'])
        # emails << imap.find(:what => :last, :count => count, :order => :asc, :keys => ['from', 'youtube'])
        # emails << imap.find(:what => :last, :count => count, :order => :asc, :keys => ['body', 'youtube'])
        # emails.flatten!
        # emails.uniq!
        arr = []
        emails.each {|e| arr << EmailService.get_recovery_email(e)}
        arr.reject!{|e| e[:body].blank?}
        arr.sort!{|a, b| a[:date] <=> b[:date]}
        arr.each do |e|
          recovery_inbox_email = RecoveryInboxEmail.where(message_id: e[:message_id], email_account_id: email_account.id).first_or_initialize
          unless recovery_inbox_email.id.present?
            recovery_inbox_email.attributes = e
            recovery_inbox_email.identify_email_type
            recovery_inbox_email.save
            if [RecoveryInboxEmail.email_type.find_value("Youtube channel has been suspended").value].include?(recovery_inbox_email.email_type.value) && Rails.env.production?
              BotServer.kill_all_zenno
              if Setting.get_value_by_name("RecoveryInboxEmail::SEND_ALERTS_ENABLED").to_s == "true"
                Utils.pushbullet_broadcast("New blocked youtube channel!", "It was detected by recovery inbox email.")
                BroadcasterMailer.new_blocked_youtube_channel
              end
            end
            if [RecoveryInboxEmail.email_type.find_value("Action required: Your Google Account is temporarily disabled").value, RecoveryInboxEmail.email_type.find_value("Google Account has been disabled").value, RecoveryInboxEmail.email_type.find_value("Google Account has been disabled (FR)").value, RecoveryInboxEmail.email_type.find_value("Google Account disabled").value].include?(recovery_inbox_email.email_type.value) && recovery_inbox_email.email_account.is_active && recovery_inbox_email.date > Time.now - 24.hours
              email_account = recovery_inbox_email.email_account
              email_account.is_active = false
              email_account.save(validate: false)
            end
            #strikes logic detection
            if [58,59,60,61,62,63].include?(recovery_inbox_email.email_type.value)
              if Setting.get_value_by_name("RecoveryInboxEmail::SEND_ALERTS_ENABLED").to_s == "true"
                BroadcasterMailer.new_youtube_channel_strike
              end
              BotServer.kill_all_zenno
            end
          end
        end
      end
    end

    def init_recovery_email(user_name, password)
      Mail::IMAP.new({:address  => "imap.yandex.ru", :port => 993, :user_name => user_name, :password => password, :enable_ssl => true})
    end

    def get_recovery_email(mail)
      sender = mail.from.to_a.join(",")
      body = if sender.include?("google.com") || sender.include?("youtube.com")
        clear = mail.body.raw_source.gsub("3D", "")
        doc = Nokogiri::HTML(clear.force_encoding(Encoding::UTF_8))
        text = ActionView::Base.full_sanitizer.sanitize(doc.css('body').to_html).split("delsp=yes").last.gsub("Content-Type: text/plain; charset=UTF-8\r\nContent-Transfer-Encoding: 7bit\r\nContent-Disposition: inline", "").gsub("Content-Type: text/html; charset=UTF-8\r\nContent-Transfer-Encoding: 7bit\r\nContent-Disposition: inline", "").gsub("=\r\n", "").gsub("\n", " ").gsub("\r", " ").gsub(/et:([1-9][0-9]*)/, "").gsub("&amp;", "&").gsub("&nbsp;", " ").split("quoted-printable").last.split("Content-Disposition: inline ").first.split(" --").first.gsub("=C2=A9", "").gsub("=C2=A0", "").gsub("39;", "'").gsub(/[\u0080-\u00ff]/, "").gsub("&copy;", "").gsub("div&gt;", "").gsub("tr&gt;", "").split("}}").last.to_s.squeeze(" ").split("} }").last.to_s.gsub("td&gt;", "").gsub("html", "").gsub("tbody", "").gsub("&gt;", "").gsub("?", "? ").gsub("!", "! ").gsub(",", ", ").gsub("\t", " ").gsub("=20 ", "").gsub(" =20", "").squeeze(" ").gsub("USA table", "USA").gsub("&#", "").gsub("=E2=80=99", "'").gsub("=E2=80=93", "-").gsub("=E2=80=A2", "•").gsub("=E2=80=A6", "...").gsub("=E2=80=AA", "").gsub("=E2=80=8E", "").gsub("E2=80=9D", "'").gsub("=E2=80=9C", "'").gsub("=E2=80=A4", ".").gsub("=C3=AA", "ê").gsub("=C3=A0", "à").gsub("=C3=A8", "è").gsub("=C3=A9", "é").gsub("&lt;br", "").gsub(/body{.*}/, "").gsub("USA body", "USA").gsub(" table", " ").gsub(".table", ". ").gsub(")span", ")").squeeze(" ").strip
        if text.include?("Welcome to Gmail")
          text = "*Welcome to Gmail" + text.split("Welcome to Gmail").last.gsub("! *", "!*")
        end
        text
      else
        nil
      end
      {sender: sender, subject: mail.subject, body: body, date: mail.date, message_id: mail.message_id}
    end

    def delay_retrieve_emails(email_account_id, minutes_delay = 15)
      dj_id = Delayed::Job.where("queue = ?", DelayedJobQueue::RECOVERY_INBOX_EMAILS).where("handler like ?","%email_account_id: #{email_account_id}\n%").first.try(:id)
      if dj_id.present?
        DelayedJobService.restart_job(dj_id)
      else
        Delayed::Job.enqueue(RecoveryInboxEmailsJob.new(email_account_id), queue: DelayedJobQueue::RECOVERY_INBOX_EMAILS, priority: DelayedJobPriority::HIGH, run_at: minutes_delay.minutes.from_now)
      end
    end
  end
end
