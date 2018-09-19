namespace :templates do
  root to: 'aae_projects#index'
  scope :aae_projects do
    get 'generate_guid' => 'aae_projects#generate_guid'
  end
  resources :aae_projects do
      get 'preview_thumbnail'
      get 'preview_video'
  end
	scope :aae_project_texts do
		get 'correct_static_texts' => 'aae_project_texts/correct_static_texts#index'
	end
  resources :aae_project_texts do
		patch 'correct' => 'aae_project_texts/correct_static_texts#update'
	end
  resources :aae_project_images
  get "aae_project_dynamic_texts/add_value" => "aae_project_dynamic_texts#add_value"
  get "aae_project_dynamic_texts/quick_edit" => "aae_project_dynamic_texts#quick_edit"
  get "aae_project_dynamic_texts/report" => "aae_project_dynamic_texts#report"
  resources :aae_project_dynamic_texts
  resources :dynamic_aae_projects, only: %w(index show) do
    get "texts"
    get "images"
    get "rendered_video"
    get "rendered_video_thumb"
  end

	resources :test_aae_projects, only: %w(index create new destroy) do

	end
  get "selected_items" => "image_templates#selected_items"
  resources :image_templates do
    get 'preview_sample'
    get 'texts'
    get 'fields'
  end
  resources :image_template_texts, :image_template_images, except: :show
end
