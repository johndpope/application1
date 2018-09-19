namespace :shared_media do
  root to: 'images#index'

	get 'images/local_import'
	get 'images/browse'
	post 'images/upload'
  get 'images/update_uploaded_files'
  post 'images/group_update'
  get 'images/products_for_client'
  resources :images do
    get 'dashboard', action: :dashboard, on: :collection
    get 'region1_coverage', on: :collection
    get 'region2_coverage', on: :collection
  end

  resources :audios do
  end

  resources :videos do
  end

end
