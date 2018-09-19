class EchoMailer < ActionMailer::Base
	default from: 'sales@echovideoblender.com'
  TEST_ACCOUNTS = "zavorotnii@gmail.com,tmriordan@gmail.com,tmriordan1@yahoo.com,royce@machonemediagroup.com,simeniuk.natasha@gmail.com"
  BCC = "zavorotnii@gmail.com,tmriordan@gmail.com,royce@machonemediagroup.com"
  SMTP_SETTINGS = {user_name: CONFIG['sales_smtp']['user_name'], password: CONFIG['sales_smtp']['password']}

	def dealer_first_email(receivers, dealer, admin_user = nil)
    #temporary
    #TODO replace
    subject = ["Reaching Local Customers Through Dealer Tagged Video Marketing",
      "<manufacturer_name/> Product Video Marketing to Grow Your Client Base and Brand Your Company",
      "Clients Search Locally for Products & Services – Video Marketing Will Get Your Company Seen",
      "Use Video Marketing to Tell Your Company Story in Your Local Markets ",
      "Clients Love Watching Videos So Give Them What They Want – Dealer Associated Product Videos",
      "Local Mobile Users Search for <manufacturer_name/> Dealers by Watching Product Videos. Does Your Company Use Video Marketing?",
      "Build Trust & Get Found by Local Clients Through <manufacturer_name/> Product Video Marketing"].shuffle.first.gsub("<manufacturer_name/>", dealer.brand_id.to_s)
    @why_video_marketing_list = ["<b>Video Boosts Sales</b> – <span class='red-txt'><b>74%</b></span> of users who watched an explainer video about a product subsequently bought the product",
      "<b>Video Builds Trust</b> – <span class='red-txt'><b>57%</b></span> of consumers report that videos gave them more confidence to purchase online",
      "<b>Video Generates High ROI</b> – <span class='red-txt'><b>83%</b></span> of businesses state that video produces a good return on investment",
      "<b>Google Loves Videos</b> – You’re <span class='red-txt'><b>53</b></span> times more likely to show up high in search results using video as Google owns YouTube",
      "<b>Videos Appeal to Mobile Users</b> – <span class='red-txt'><b>90%</b></span> of consumers watch videos from their mobile devices",
      "<b>Explainer Videos Are Convincing</b> - <span class='red-txt'><b>98%</b></span> of users say they have watched an explainer video to learn more about a product or service",
      "<b>Video Overcomes Consumer Laziness</b> – <span class='red-txt'><b>68%</b></span> of consumers would prefer watching an Explainer Video to solve any product related problems, issues or decisions",
      "<b>Video Encourages Social Shares</b> – <span class='red-txt'><b>76%</b></span> of users say that they would share a branded video with their friends if it was entertaining",
      "<b>Video Ads Produce Highest Click Through Rates</b> – The average click through rate of video ads is 1.84% - the highest of all digital ad formats",
      "<b>Video Produces High Ad Recall</b> – Consumers prefer video content to reading",
      "<b>Video Breaks the Ice With Customers</b> – Many potential buyers report a fear of talking to sales people",
      "<b>Superior Manufacturer Product Videos</b> – Content is King and your manufacturer has produced high quality product videos",
      "<b>Dealer Tagging to Build Your Brand</b> – Linking your company name to a strong manufacturer brand builds consumer trust, confidence and loyalty"].shuffle.first(3)
    @why_local_advertising_list = ["<span class='red-txt'><b>82%</b></span> of local searchers follow up offline by making either an in-store visit, phone call or purchase",
      "<span class='red-txt'><b>74%</b></span> of Internet users perform local searches",
      "<span class='red-txt'><b>61%</b></span> of local searches result in a purchase",
      "<span class='red-txt'><b>59%</b></span> of consumers use Google every month to find a reputable local business",
      "<span class='red-txt'><b>37%</b></span> of all searches are now done on mobile devices",
      "<span class='red-txt'><b>46%</b></span> of all Google searches are local",
      "<span class='red-txt'><b>64%</b></span> of local customers use search engines and directories as their main way to find a local business",
      "<span class='red-txt'><b>50%</b></span> of local mobile searchers look for business information (i.e. address, phone, etc.)",
      "<span class='red-txt'><b>78%</b></span> of local mobile searches result in an offline purchase"].shuffle.first(3)
    begin
      @dealer = dealer
      @home_url = "#{Rails.configuration.routes_default_url_options[:host]}#{Rails.application.routes.url_helpers.sandbox_root_path}"
      @get_started_url = "#{Rails.configuration.routes_default_url_options[:host]}#{Rails.application.routes.url_helpers.landing_sandbox_video_marketing_campaign_forms_path(dealer_id: @dealer.id, industry_id: @dealer.industry_id, is_email_registration: true)}"
      mail_receivers = Rails.env.production? ? receivers : TEST_ACCOUNTS
      bcc = Rails.env.production? ? BCC : TEST_ACCOUNTS
      subject = "#{subject}#{' (TEST)' unless Rails.env.production?}"
		  msg = mail(to: mail_receivers, bcc: bcc, subject: subject)
      msg.delivery_method.settings.merge!(SMTP_SETTINGS)
      msg.deliver!
      dealer.sent_emails << SentEmail.new(email_type: SentEmail.email_type.find_value("First Dealer Sign Up Invitation").value, sender: msg.from.to_a.join(","), receiver: mail_receivers, bcc: msg.bcc.to_a.join(","), subject: subject, body: msg.body.raw_source, admin_user_id: admin_user.try(:id))
    rescue Exception => e
      puts e
      Utils.pushbullet_broadcast("Something wrong with SMTP", "Something wrong with SMTP on sales@echovideoblender.com account. Please review!")
    end
	end

  def custom_mail(receivers, subject, body)
    begin
      @body = body
      mail_receivers = Rails.env.development? ? 'zavorotnii@gmail.com' : receivers
      mail(to: mail_receivers, subject: subject, body: body, content_type: 'text/html; charset=UTF-8').deliver
    rescue
      Utils.pushbullet_broadcast("Something wrong with SMTP", "Something wrong with SMTP on sales@echovideoblender.com account. Please review!")
    end
  end
end
