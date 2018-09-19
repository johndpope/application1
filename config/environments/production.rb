Broadcaster::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  config.logger ||= Logger.new(Rails.root.join('log', "#{Rails.env}.log"), 10, 500.megabytes)
  config.logger.level = 1
  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both thread web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Enable Rack::Cache to put a simple HTTP cache in front of your application
  # Add `rack-cache` to your Gemfile before enabling this.
  # For large-scale production use, consider using a caching reverse proxy like nginx, varnish or squid.
  # config.action_dispatch.rack_cache = true

  # Disable Rails's static asset server (Apache or nginx will already do this).
  config.serve_static_assets = true

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :uglifier
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = true

  # Generate digests for assets URLs.
  config.assets.digest = true

  # Version of your assets, change this if you want to expire all your assets.
  config.assets.version = '1.0'

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Set to :debug to see everything in the log.
  config.log_level = :info

  # Prepend all log lines with the following tags.
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups.
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets.
  # application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
  # config.assets.precompile += %w( search.js )

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Disable automatic flushing of the log to improve performance.
  # config.autoflush_log = false

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new
	config.routes_default_url_options = {host: 'http://broadcaster.beazil.net'}
	config.aae_project_generator[:root] = '/home/broadcaster/storage'

  config.action_mailer.delivery_method = :smtp
	config.action_mailer.smtp_settings = {
		address: CONFIG['smtp']['address'],
		port: CONFIG['smtp']['port'],
		domain: CONFIG['smtp']['domain'],
		user_name: CONFIG['smtp']['user_name'],
		password: CONFIG['smtp']['password'],
		authentication: CONFIG['smtp']['authentication'],
		enable_starttls_auto: true
	}
end

#don't remove this config. A lot of files were uploaded using these options
Paperclip::Attachment.default_options[:path] = "#{Rails.root}/public/system/:base_class/:id_partition/:style/:basename.:extension"
Paperclip::Attachment.default_options[:url] = "/system/:base_class/:id_partition/:style/:basename.:extension"

#Right now temporary solution is to use Rails.configuration.routes_default_url_options[:host]
#TODO: fix problem with routing error for action "create" accuring when we use route_path
#TODO: uncomment when problem with routing_path is solved
#Rails.application.routes.default_url_options[:host] = 'broadcaster.beazil.net'
