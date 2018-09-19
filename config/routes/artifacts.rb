namespace :artifacts do
  root to: 'common#home'

	scope :images do
		resources :human_photos, only: 'index'
	end

  resources :images do
    get 'import', on: :collection
    get 'local_import', on: :collection
    get 'region1_coverage', on: :collection
    get 'region2_coverage', on: :collection
    post 'upload', on: :collection
    post 'gravity'
    get 'aspect_cropping_variations'
    match 'report_by_localities', via: [:get, :post], on: :collection
    get 'report_by_industries', on: :collection
    get 'report_by_admin_users', on: :collection
    get 'get_coordinates', action: :get_coordinates, on: :collection, as: :get_coordinates
    get 'set_rating/:rating', action: :set_rating, as: :set_rating
  end

  scope :image_blender,controller: :image_blender do
    get '',action: :index, as: :image_blender
    post 'blend', as: :blend_image
    get 'image_template_settings', as: :image_template_settings
    get 'select_image/:image_field', action: :select_image, as: :select_image
    get 'search', action: :search, as: :image_blender_search
    post 'import_image', as: :import_image
    get 'templates_by_type', action: :templates_by_type, as: :templates_by_type
    get 'select_logo', action: :select_logo, as: :select_logo
    get 'save_image', as: :save_image
    get 'image_info/:image_id', action: :image_info, as: :image_info
  end
  resources :blended_images do
    get '', action: :index, as: :blended_images
    get 'show_modal_image_text'
    get 'show_modal_image_image'
  end

  resources :audios do
    get 'local_import', on: :collection
    post 'upload', on: :collection
    get 'youtube_audio_library', on: :collection
    get 'group_update', on: :collection
    get 'import'
  end

  post '/images/reject', as: :reject_image

  resources :search_suggestions, only: :index

  scope :icons, controller: :icon do
    get :index, as: :icon
    get :browse_icon, as: :browse_icon
    get :search, as: :search_icon
    post :settings, as: :apply_color_schema
    post :save, as: :save_icon
    get :get_icon_file, as: :get_icon_file
    delete :delete, as: :delete_files
  end
end
