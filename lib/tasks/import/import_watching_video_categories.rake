namespace :db do
  namespace :seed do
    task :import_watching_video_categories => :environment do
      puts "import watching video categories task started"
      if WatchingVideoCategory.all.size == 0
        CSV.foreach('db/watching_video_categories.csv',{:headers=>false,:col_sep=>';'}) do |row|
          WatchingVideoCategory.create(name: row[0], phrases: row[1])
        end
      end
      puts "import watching video categories task finished"
    end
  end
end
