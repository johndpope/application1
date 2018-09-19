crumb :public do
	link 'Public'
end

crumb :media_credits do
	parent :public
	link 'Media Credits'
end

crumb :youtube_videos_credits do
	parent :media_credits
	link 'Youtube Videos', public_credits_youtube_videos_path
end

crumb :youtube_video_credits do |yv|
	parent :youtube_videos_credits
	link yv.id
end
