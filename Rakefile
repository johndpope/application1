# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Broadcaster::Application.load_tasks

# Do not create database structure dump in production
Rake::Task["db:structure:dump"].clear if Rails.env.production?
