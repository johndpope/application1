class ActionDispatch::Routing::Mapper
	def draw(routes_name)
		instance_eval(File.read(Rails.root.join("config/routes/#{routes_name}.rb")))
	end
end

Broadcaster::Application.routes.draw do
  get "videos/index"
  get "videos/show"
  resources :svgs

  get "templates/index"
  get "templates/new"
  get "templates/create"
  get "templates/destroy"
  get "content_blenders/show"
	mount Rich::Engine => '/rich', as: 'rich'
	mount_roboto

	devise_for :admin_users, ActiveAdmin::Devise.config
	ActiveAdmin.routes(self)

	root 'dashboard#index'

	[:common, :artifacts, :geobase, :sandbox, :templates, :admin, :public, :shared_media].each { | r | draw r }

	devise_for	:users, path_names: {sign_in: "login", sign_out: "logout"},
							:controllers => {:omniauth_callbacks => 'omniauth_callbacks', :sessions => 'user_sessions'}

	get 'googlee15abfbabab7305b' => 'google_site_verification#googlee15abfbabab7305b', :constraints => { :format => 'html' }
end
