class RecoveryInboxEmail < ActiveRecord::Base
  READ_EMAILS_ENABLED = true
  SEND_ALERTS_ENABLED = true
  GMAIL_WAIT_FOR_RESULT_DAYS = 3
  YOUTUBE_WAIT_FOR_RESULT_DAYS = 3
  EMAIL_TYPES = {
		"Account not eligible to be reinstated" => 1,
		"Wait for the result" => 2,
		"Reenabled your account" => 3,
    "YouTube account is currently disabled" => 4,
    "Try signing in to your account and verifying your phone number" => 5,
    "Account can no longer be recovered" => 6,
    "You should now be able to log in normally" => 7,
    "Email address is not associated with an active google account" => 8,
    "Signin into your account and pass captcha" => 9,
    "Confirmed that account is still active" => 10,
    "Share your google account recovery experience" => 11,
    "Account can not be restored" => 12,
    "Provide additional information to verify that you own this account?" => 13,
    "Review blocked sign-in attempt" => 14,
    "Access for less secure apps has been turned on" => 15,
    "Action required: Your Google Account is temporarily disabled" => 16,
    "Someone has your password" => 17,
    "Google Account has been disabled" => 18,
    "New sign-in" => 19,
    "Verify added email" => 20,
    "Password changed" => 21,
    "Google Account has been suspended" => 22,
    "Recovery phone number changed" => 23,
    "Recovery email address changed" => 24,
    "New device signed" => 25,
    "Google+ was created using a device with an older version of our software" => 26,
    "Search Console - New owner" => 27,
    "Google Verification Code" => 28,
    "Google Password Assistance" => 29,
    "Sign-in attempt prevented" => 30,
    "You have recently sent an appeal" => 31,
    "Youtube account is not in violation" => 32,
    "Decided to keep your account suspended" => 33,
    "Gmail Forwarding Confirmation" => 34,
    "Welcome to Gmail" => 35,
    "Other" => 36,
    "Ready to publish your video?" => 37,
    "Received your account appeal" => 38,
    "Youtube channel has been suspended" => 39,
    "Top suggested Google+ Pages for you" => 40,
    "Welcome to YouTube!" => 41,
    "Welcome to YouTube with Google+" => 42,
    "Congrats, your video is now on YouTube!" => 43,
    "New comment on YouTube Video" => 44,
    "Welcome to Google+" => 45,
    "Google+ endless discovery" => 46,
    "Getting Started with Google AdWords" => 47,
    "Stay more organized with Gmail's inbox" => 48,
    "Search Console - Improve the search presence" => 49,
    "Three tips to get the most out of Gmail" => 50,
    "Get more out of your new Google Account" => 51,
    "The best of Gmail, wherever you are" => 52,
    "Search Console - Monitor the Google Search traffic" => 53,
    "After review, your account is eligible for reinstatement" => 54,
    "Account was deleted due to a violation that was left unresolved" => 55,
    "You can still recover your account through our password recovery process" => 56,
    "Critical security alert - someone just used your password" => 57,
    "1st Community Guidelines Strike" => 58,
    "2nd Community Guidelines Strike" => 59,
    "3rd Community Guidelines Strike" => 60,
    "1st Copyright Strike" => 61,
    "2nd Copyright Strike" => 62,
    "3rd Copyright Strike" => 63,
    "Check your Google Account’s security status" => 64,
    "Your account has already been permanently deleted" => 65,
    "Will review your request and be in touch with an update as soon as possible" => 66,
    "Security issues found on your Google account" => 67,
    "YouTube email subscription summaries" => 68,
    "The recovery email for your account was changed" => 69,
    "This email address has just been registered as the secondary email" => 70,
    "Introducing the new Search Console" => 71,
    "Google Account has been disabled (FR)" => 72,
    "Google Account disabled" => 73
	}
  PATTERNS = {
    1 => ["your account is not eligible to be reinstated due to a violation of our terms of service"],
    2 => ["there is already a pending appeal for your account", "please wait for the result of your current appeal"],
    3 => ["we have reenabled your account", "you will be asked to verify your phone number"],
    4 => ["your videos have not been deleted", "but are not visible to anyone"],
    5 => ["try signing in to your account", "verifying your phone number", "if you are unable to verify your phone number", "then your google account is no longer eligible to be reinstated"],
    6 => ["your account can no longer be recovered"],
    7 => ["you should now be able to log in normally"],
    8 => ["email address you inquired about is not associated with an active google account"],
    9 => ["please try signing into your account", "and typing the letters in the distorted picture"],
    10 => ["looked into your account and confirmed that it is", "still active"],
    11 => ["best customer support experience", "recently contacted our support team to regain access"],
    12 => ["but unfortunately your account can't be restored", "have been used in a way that violated google's policies"],
    13 => ["can you provide additional information to verify that you own this account"],
    14 => ["review blocked sign-in attempt", "just blocked someone from signing into your google account"],
    15 => ["access for less secure apps has been turned on", "no longer protected by modern security standards"],
    16 => ["action required", "your google account is temporarily disabled"],
    17 => ["someone has your password"],
    18 => ["google account", "disabled", "recovery email", "mistake", "deleted"],
    19 => ["new sign-in"],
    20 => ["verify your added email", "verify this request"],
    21 => ["password changed", "was recently changed"],
    22 => ["google account has been suspended"],
    23 => ["recovery phone number changed", "review your recently used devices"],
    24 => ["recovery email address changed", "review your recently used devices"],
    25 => ["new device signed"],
    26 => ["new google+ account was created using a device with an older version of our software"],
    27 => ["search console new owner", "has been added as an owner"],
    28 => ["google verification code"],
    29 => ["to initiate the password reset process"],
    30 => ["sign-in attempt prevented", "app that doesn't meet modern security standards"],
    31 => ["looked into your request", "recently sent an appeal", "cannot appeal a second time"],
    32 => ["not in violation", "unsuspended your account"],
    33 => ["account suspension appeal", "keep your account suspended"],
    34 => ["requested to automatically forward mail"],
    35 => ["welcome to gmail"],
    37 => ["almost done", "all you have to do now is publish your video"],
    38 => ["received your account appeal", "will get back to you as soon as possible"],
    39 => ["due to repeated or severe violations", "has been suspended"],
    40 => ["top suggested google+ pages"],
    41 => ["largest collection of videos ever"],
    42 => ["youtube is more fun with friends", "makes youtube more tubular"],
    43 => ["way to go", "your video is now on youtube"],
    44 => ["commented on your video", "comments and replies", "youtube"],
    45 => ["explore the topics you love", "because you signed up for a google+ account"],
    46 => ["dive right in and follow what you love"],
    47 => ["successfully signed up for adwords"],
    48 => ["inbox puts you in control meet the inbox", "inbox sorts your email into categories"],
    49 => ["search console improve the search presence"],
    50 => ["three tips to get the most out of gmail"],
    51 => ["so glad you decided to try out gmail"],
    52 => ["the best of gmail, wherever you are"],
    53 => ["search console monitor the google search traffic"],
    54 => ["your account is eligible for reinstatement", "to reinstate your account"],
    55 => ["was deleted due to a violation", "that was left unresolved", "please visit our account recovery page immediately"],
    56 => ["although your account was recently deleted", "you can still recover it through our password recovery process for a little while longer"],
    57 => ["someone just used your password to try to sign in to your account", "google blocked them, but you should check what happened"],
    58 => ["this is the first strike applied to your account", "assigned a community guidelines strike"],
    59 => ["this is the second strike applied to your account", "assigned a community guidelines strike"],
    60 => ["this is the third strike applied to your account", "assigned a community guidelines strike"],
    61 => ["1 copyright strike", "if you get multiple copyright strikes"],
    62 => ["1 copyright strikes", "if you get multiple copyright strikes"],
    63 => ["3 copyright strikes"],
    64 => ["upgraded", "to give you specific", "recommendations to strengthen the security"],
    65 => ["we can only restore access to a deleted", "if the request is made within a relatively short period of time", "your account has already been permanently deleted"],
    66 => ["thank you for contacting us about your disabled google account", "the google accounts team will review your request and be in touch with an update as soon as possible", "most requests take 2 business days to review, but some might take longer"],
    67 => ["security", "issue", "found", "upgraded the security checkup to give you specific, personalized recommendations to strengthen the security"],
    68 => ["subscriptions", "youtube sends email summaries like these so you can keep up with your channel subscriptions"],
    69 => ["the recovery email for your account was changed", "if you didn't change it, you should check what happened"],
    70 => ["this email has been linked to", "has just been registered as the secondary email"],
    71 => ["search console is introducing a redesigned product to help you manage your presence on google search", "we recommend checking your current status using the new search console today"],
    72 => ["compte google", "désactivé", "e-mail de récupération", "si vous pensez qu'il s'agit d'une erreur"],
    73 => ["google account disabled", "was disabled because it looked like it was being used in a way that violated", "disabled accounts are eventually deleted along with emails"]
  }
  extend Enumerize
	enumerize :email_type, :in => EMAIL_TYPES
  belongs_to :email_account


  def identify_email_type
    self.email_type = nil
    RecoveryInboxEmail::PATTERNS.each do |key, value|
      if value.all? {|e| self.body.to_s.downcase.include? e}
        self.email_type = key
        break
      end
    end
    self.email_type = RecoveryInboxEmail.email_type.find_value("Other").value if self.email_type.nil?
  end
end