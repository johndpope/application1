Broadcaster::Application.configure do
	root = '/tmp/broadcaster'
	dynamic_aae_projects = "#{root}/dynamic_aae_projects"
	youtube = "#{root}/youtube"
	youtube_videos = "#{youtube}/videos"
	youtube_video_thumbnails = "#{youtube_videos}"
	youtube_channels = "#{youtube}/channels"
	options = {
		root: root,
		dynamic_aae_projects:{
			root: dynamic_aae_projects
		},
		youtube:{
			root: youtube,
			videos:{
				root: youtube_videos,
				thumbnails: "#{youtube_videos}/thumbnails"
			},
			channels:{
				root: youtube_channels,
				arts: "#{youtube_channels}/arts"
			}
		}
	}
	config.temporary_files = options
end
