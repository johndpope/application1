namespace :youtube do
	desc "Uploads youtube videos"
  	task :upload_videos, [:daily_limit, :limit]=> :environment  do |t,args|
  		args.with_defaults(daily_limit: 5) #daily limit per google account
  		args.with_defaults(limit: 100) #upload operations limit
		Youtube::upload_videos(args.daily_limit,args.limit)
	end

	desc "Determines duplicated uploaded youtube videos"
  	task get_duplicates: :environment do
		Youtube::get_duplicates()
	end

	desc "Delete youtube videos"
  	task delete_videos: :environment do
		Youtube::delete_videos()
	end

	desc "Video statistics"
	task video_statistics: :environment do
		Youtube::video_statistics()
	end

	task upload_video: :environment do
		return if !Utils.open_for_business?
		daily_limit = DailyPostingPlan.select(:value).where(["source = ? AND created_at::date = ?", 'UploadYoutubeVideo', Time.now.strftime('%Y-%m-%d')]).first
		return if !daily_limit

		work_time = 9*60*60
		avg_upload_time = 210
		upload_limit = 100
		min_avg_upload_delay = 60
		avg_upload_delay = (work_time - avg_upload_time*upload_limit)/upload_limit

		last_video_upload = UploadYoutubeVideo.where(["created_at::date = ?", Time.now.strftime("%Y-%m-%d")]).order(created_at: :desc).first

		return if last_video_upload && (last_video_upload.created_at + avg_upload_delay.seconds) > Time.now

		Youtube::upload_video(5,Time.now + rand(min_avg_upload_delay,avg_upload_delay).seconds)
	end
end
