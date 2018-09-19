# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require 'spec_helper'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
require 'simplecov'
require 'webmock/rspec'
require 'vcr'
require 'capybara/rails'

SimpleCov.start do
  add_filter '/spec/'
end
# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.check_pending!

Rails.logger.level = 4

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!


  keep = [
    'geobase_countries', 'geobase_regions', 'geobase_localities',
    'geobase_localities_zip_codes', 'geobase_zip_codes', 'geobase_landmarks'
  ]
  config.before(:suite) do
    FileUtils.rm_rf(Dir["#{Rails.root}/public/system/test/*"])
    DatabaseCleaner.clean_with(:deletion, except: keep)
  end
  config.before(:each) { DatabaseCleaner.strategy = :transaction }
  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :deletion, { except: keep }
    if Capybara.current_driver == :selenium
      page.driver.browser.manage.window.maximize
    end
    page.driver.allow_url('*') if Capybara.current_driver == :webkit
  end
  config.before(:each, transactional: true) do
    DatabaseCleaner.strategy = :deletion, { except: keep }
  end
  config.before(:each) { DatabaseCleaner.start }
  config.after(:each) { DatabaseCleaner.clean }
end

Capybara.register_driver :selenium do |app|
  require 'selenium/webdriver'
  Selenium::WebDriver::Firefox::Binary.path = ENV['FIREFOX_BINARY_PATH'] || Selenium::WebDriver::Firefox::Binary.path
  Capybara::Selenium::Driver.new(app, :browser => :firefox)
end
Capybara.javascript_driver = :webkit
Capybara.server_port = 31337

VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.ignore_hosts '127.0.0.1', 'localhost'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.allow_http_connections_when_no_cassette = true
  config.default_cassette_options = { record: :new_episodes }
end
