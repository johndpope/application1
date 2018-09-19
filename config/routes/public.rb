namespace :public do
	resources :clients, only: [:show] do
		get 'dashboard'
    get 'dashboard_content'
		get 'youtube_channels'
		get 'youtube_videos'
		get 'client_landing_pages'
    get 'assets'
		get 'report'
	end

	namespace :credits do
		get '/', to: redirect('/public/credits/youtube/videos')
		namespace :youtube do
			resources :videos, only: [:show, :index] do

			end
		end

		resources :videos, param: :blended_video_id, only: [:show, :index], controller: "youtube/videos" do

		end
	end
end
