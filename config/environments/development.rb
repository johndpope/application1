Broadcaster::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default_url_options = { host: 'localhost:3000' }

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true
	config.routes_default_url_options = {host: 'http://localhost:3000'}
	config.aae_project_generator[:root] = '/media/DATA/aae_projects'

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
  # config.action_mailer.perform_deliveries = true
  # config.action_mailer.raise_delivery_errors = true
end

#dont't remove this config
Paperclip::Attachment.default_options[:path] = "#{Rails.root}/public/system/:base_class/:id_partition/:style/:basename.:extension"
Paperclip::Attachment.default_options[:url] = "/system/:base_class/:id_partition/:style/:basename.:extension"

#Right now temporary solution is to use Rails.configuration.routes_default_url_options[:host]
#TODO: fix problem with routing error for action "create" accuring when we use route_path
#TODO: uncomment when problem with routing_path is solved
#Rails.application.routes.default_url_options[:host] = 'localhost:3000'
