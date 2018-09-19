namespace :db do
  namespace :seed do
    task :assign_watching_video_categories => :environment do
      puts "assign watching video categories task started"
      watching_video_categories = WatchingVideoCategory.all
      puts "please run import watching video categories rake task first and repeat again" if watching_video_categories.empty?
      GoogleAccountActivity.order(created_at: :desc).each do |gaa|
        if gaa.watching_video_categories.empty?
          updated_at = gaa.updated_at
          gaa.watching_video_categories << watching_video_categories.sample(Setting.get_value_by_name("WatchingVideoCategory::WATCHING_VIDEO_CATEGORIES_NUMBER").to_i)
          gaa.update_attribute("updated_at", updated_at)
        end
      end
      puts "assign watching video categories task finished"
    end
  end
end
