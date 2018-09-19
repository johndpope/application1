require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

CONFIG = YAML.load(File.read(File.expand_path('../application.yml', __FILE__)))
CONFIG.merge! CONFIG.fetch(Rails.env, {})

module Broadcaster
	class Application < Rails::Application
		# Settings in config/environments/* take precedence over those specified here.
		# Application configuration should go into files in config/initializers
		# -- all .rb files in that directory are automatically loaded.

		config.i18n.enforce_available_locales = false

		# Custom directories with classes and modules you want to be autoloadable.
		Dir.glob(Rails.root + "app/decorators/**/*_decorator*.rb").each do | c |
			require_dependency(c)
		end

		config.autoload_paths += %W(#{config.root}/lib/modules)
		config.autoload_paths += %W(#{config.root}/lib/thumbnailer)
		config.autoload_paths += %W(#{config.root}/lib/imagemagick_scripts)
		config.autoload_paths += %W(#{config.root}/lib/image_filters)

		# Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
		# Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
		# config.time_zone = 'Central Time (US & Canada)'

		# The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
		config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**/*.{rb,yml}').to_s]
		config.i18n.default_locale = :en
		config.i18n.available_locales = [:en, :es]

		config.encoding = 'utf-8'

		ENV['PGHOST'] = CONFIG['database']['host']
		ENV['PGPORT'] = CONFIG['database']['port']
		ENV['PGUSER'] = CONFIG['database']['user']
		ENV['PGPASSWORD'] = CONFIG['database']['password']
    ENV['PUMA_WORKERS'] = CONFIG['rails']['application']['puma']['workers']
    ENV['PUMA_THREADS_MIN'] = CONFIG['rails']['application']['puma']['threads_min']
    ENV['PUMA_THREADS_MAX'] = CONFIG['rails']['application']['puma']['threads_max']
    ENV['PORT'] = CONFIG['rails']['application']['port']

		config.active_record.schema_format = :sql
		config.active_support.escape_html_entities_in_json = false

		config.aae_project_generator = {
			test_client_id: 1,
	    root: '/storage',
	    original_window_base_path: 'Y:\storage',
	    target_window_base_path: 'c:\aae_projects'
		}

		config.paperclip_attachment_default_options = {
			path: ":rails_root/public/system/:class/:attachment/:id_partition/:style/:filename",
			url: "/system/:class/:attachment/:id_partition/:style/:filename"
		}
	end
end
