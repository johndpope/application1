# Load the Rails application.
require File.expand_path('../application', __FILE__)
require 'active_record/connection_adapters/postgresql_adapter'

# Initialize the Rails application.
Broadcaster::Application.initialize!

Broadcaster::Application.configure do
	ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:primary_key] = 'bigserial primary key'

	config.google_api = {
		scopes: [
			'https://www.googleapis.com/auth/youtube',
			'https://www.googleapis.com/auth/yt-analytics.readonly'
		].join(' '),
		application_name: 'Broadcaster',
		application_version: '1.0'
	}

	# config.gem 'whenever', :lib => false, :source => 'http://gems.github.com'
end

ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
	html_tag.html_safe
end
