namespace :sandbox do
  root to: 'home#index'
  get 'how_it_works' => 'home#how_it_works'
  get 'contact_us' => 'contact_us#index', as: :contact_us_index
  get ':uuid/contact_us' => 'contact_us#index'
  post 'contact_us' => 'contact_us#create'
  get 'contact_us/listing' => 'contact_us#listing', as: :contact_us_listing
  post 'contact_us/show' => 'contact_us#show'
  post 'contact_us/read' => 'contact_us#read'
  post 'contact_us/inbox' => 'contact_us#inbox'
  delete 'contact_us/:id/destroy' => 'contact_us#destroy', as: :destroy_contact_us

  resources :clients, param: :uuid, controller: "sandbox_clients", only: [:show] do
    get "content_blender_video_campaign_options/:locality_id" => 'sandbox_clients#content_blender_video_campaign_options'
    get 'video_campaign/:locality_id' => 'sandbox_clients#video_campaign'
    get 'contact_us' => 'contact_us#index'

    resources :video_blenders, only: :show do
      get 'video_info/:video_id' => 'video_blenders#video_info'
      post 'blend'
      get 'refresh_pattern', on: :collection
      get ':id/regenerate_channel_name' => 'video_blenders#regenerate_channel_name', on: :collection, as: :regenerate_channel_name
      get ':id/regenerate_channel_arts' => 'video_blenders#regenerate_channel_arts', on: :collection, as: :regenerate_channel_arts
      get 'regenerate_channel_tags', on: :collection
      get 'regenerate_channel_descriptions', on: :collection
      get 'regenerate_video_title', on: :collection
      get 'regenerate_video_descriptions', on: :collection
      get 'regenerate_video_tags', on: :collection
      get 'regenerate_channel_icon', on: :collection
      get 'regenerate_video_thumbnail_image', on: :collection
      get ':id/regenerate_youtube_channel' => 'video_blenders#regenerate_youtube_channel', on: :collection, as: :regenerate_youtube_channel
      get ':id/regenerate_youtube_video' => 'video_blenders#regenerate_youtube_video', on: :collection, as: :regenerate_youtube_video
    end
    resources :content_blenders, only: [] do
      get ':locality_id' => 'content_blenders#preview', as: :preview
    end
  end
	get 'video_marketing_campaign_forms/oauth/callback/youtube' => 'video_marketing_campaign_forms#youtube_oauth_callback', as: :youtube_oauth_callback
	resources :video_marketing_campaign_forms do
    get 'search' => 'video_marketing_campaign_forms#search', on: :collection
    patch ':id/upload_client_images' => 'video_marketing_campaign_forms#upload_client_images', on: :collection
    patch ':id/upload_license_file' => 'video_marketing_campaign_forms#upload_license_file', on: :collection
    post ':id/associate_license_to_images' => 'video_marketing_campaign_forms#associate_license_to_images', on: :collection
    get 'detect_other_dealers' => 'video_marketing_campaign_forms#detect_other_dealers', on: :collection
    get 'landing' => 'video_marketing_campaign_forms#landing', on: :collection
	  member do
			get 'youtube_channel_section' => 'video_marketing_campaign_forms#youtube_channel_section', as: :youtube_channel_section
			post 'unbind_youtube_channel' => 'video_marketing_campaign_forms#unbind_youtube_channel'
			get 'stock_images' => 'video_marketing_campaign_forms#stock_images', as: :stock_images
			get 'stock_image_templates' => 'video_marketing_campaign_forms#stock_image_templates', as: :stock_image_templates
      delete 'client_images_destroy/:image_id' => 'video_marketing_campaign_forms#client_images_destroy', as: :client_images_destroy
      get 'content_landing' => 'video_marketing_campaign_forms#content_landing'
    end
  end
end
