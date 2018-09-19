json.array!(@youtube_videos) do |youtube_video|
  json.extract! youtube_video, :id
  json.url youtube_video_url(youtube_video, format: :json)
end
