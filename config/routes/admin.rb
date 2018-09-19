namespace :admin do
	root to: 'users#index', as: :tools_root
	resources :subject_videos, only: [:index], format: true, constraints: {format: 'json'}
	resources :users, except: :show
  resources :user_companies, except: :show
	resources :rendering_machines, except: :show
	scope :users, controller: :users do
		get 'generate_password', format: true, constraints: {format: 'json'}
	end

	resources :tooltips, only: [:index, :create]

	namespace :delayed_jobs do
		resources :settings, except: :show
	end
	namespace :sandbox do
	  root to: 'home#index'
	  %w(client_categories clients video_sets videos video_campaigns video_campaign_video_stages locality_details).each do |r|
			resources r, except: :show
		end
		scope :clients do
			get 'browse/:image_type' => 'clients#browse', as: :browse
			get 'search' => 'clients#search'
		end
		scope :video_campaigns do
			get 'sandbox_clients' => 'video_campaigns#sandbox_clients'
			get 'source_videos' => 'video_campaigns#source_videos'
		end
		scope :videos do
			get 'upload' => 'videos_upload#index'
			post 'upload' => 'videos_upload#upload'
		end
		resources :youtube_channel do
			get 'add_short_description', on: :collection
		end
		resources :youtube_video
		resources :youtube_channel_image do
			post 'upload', on: :collection
		end

	end

	namespace :templates do
		resources :aae_project_validation_test_settings, except: :show
	end

	namespace :vmware do
		resources :servers, except: :show
	end

	namespace :whenever do
		resources :cron_job_groups, except: :show
		resources :cron_jobs, except: :show
	end

	namespace :makes_and_models do
		resources :product_categories
		resources :makes
		resources :models
	end
end
