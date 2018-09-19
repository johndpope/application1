PayPal::SDK.configure(
  :mode      => CONFIG['paypal']['mode'],  # Set "live" for production
  :app_id    => CONFIG['paypal']['app_id'],
  :username  => CONFIG['paypal']['username'],
  :password  => CONFIG['paypal']['password'],
  :signature => CONFIG['paypal']['signature'] )

logger ||= Logger.new("#{Rails.root}/log/paypal.log", 10, 100.megabytes)
PayPal::SDK.logger = logger
# change log level to INFO
PayPal::SDK.logger.level = Logger::DEBUG
