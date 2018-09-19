namespace :provide do  
  desc "Imports list of popular US languages into db"  
  task import_popular_us_languages: :environment do
    DataProvider::import_popular_us_languages()
  end
  
  desc "Imports list of largest US cities sorted by population"
  task import_largest_us_cities: :environment do
    DataProvider::import_largest_us_cities()
  end

  desc "Upload youtube Video"
  task upload_youtube_video: :environment do
    DataProvider::upload_youtube_video()
  end

  desc "Upload youtube Video Thumbnail"
  task upload_youtube_video_thumbnail: :environment do
    DataProvider::upload_youtube_video_thumbnail()
  end

  desc "Gets random case tags"
  task random_case_tags: :environment do
    DataProvider::get_random_case_tags()
  end

  desc "Create temp directory for thumbnails"
  task create_thumbnail_temp_dir: :environment do
    DataProvider::create_thumbnail_temp_dir()
  end  

  desc "Imports case types from legalbistro.com"
  task import_case_types: :environment do
    DataProvider::import_case_types
  end

  desc "Imports countries, regions, localities & zip codes"
  task import_geo_info: :environment do
    DataProvider::import_geo_info
  end

  desc "Imports qualifiers into database"
  task import_qualifiers: :environment do
    DataProvider::import_qualifiers
  end

  desc "Imports tag lines into database"
  task import_tag_lines: :environment do
    DataProvider::import_tag_lines
  end

  desc "Generates video params"
  task generate_video_params: :environment do
    DataProvider::generate_video_params()
  end

  desc "Generates case thumbnail"
  task generate_case_type_thumbnail: :environment do
    DataProvider::generate_case_type_thumbnail()
  end

  desc "Imports youtube video categories"
  task import_youtube_video_categories: :environment do
    DataProvider::import_youtube_video_categories()
  end

  desc "Imports tags"
  task import_tags: :environment do
    DataProvider::import_tags()
  end

  desc "Import refresh tokens"
  task import_refresh_tokens: :environment do
    DataProvider::import_refresh_tokens()
  end

  desc "Test tokens"
  task :test_tokens, [:limit]=> :environment do |t,args|
    args.with_defaults(limit:100) 
    DataProvider::test_tokens(args.limit)
  end

  desc "Test tokens"
  task :test_token, [:email]=>:environment do |t, args|
    DataProvider::test_token(args.email)
  end

  desc "Creates YoutubeVideo instances from UploadYoutubeVideo objects"
  task create_youtube_videos: :environment do
    DataProvider::create_youtube_videos()
  end

  desc "Generates random emails"  
    task :generate_random_emails, [:domain,:limit]=>:environment do |t,args|
    args.with_defaults(domain: 'sample.com')
    args.with_defaults(limit: 100)
    DataProvider::generate_random_emails(args.domain,args.limit)
  end

  desc "Generates random passwords"  
    task :generate_random_passwords, [:limit]=>:environment do |t,args|    
    args.with_defaults(limit: 100)
    DataProvider::generate_random_passwords(args.limit)
  end

  desc "Import no ip emails"  
    task :import_emails => :environment do    
    NoIpEmail.import()
  end

end