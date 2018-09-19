namespace :geobase do
  resources :countries, only: :index
  resources :regions, only: :index
  resources :localities, only: [:index, :update, :add_description, :add_info] do
    member do
      match 'add_description', via: [:get, :post]
      match 'add_info', via: [:get, :post]
    end
  end
  resources :search, only: :index
  resources :landmarks do
    match 'save', via: [:get, :post], on: :collection
  end
  resources :neighbourhoods do
    match 'save', via: [:get, :post], on: :collection
  end
end
