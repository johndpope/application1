resources :email_accounts do
  member do
    post 'save_screenshot'
  end
	resources :adwords_campaigns do
		member do
			get 'set' => 'adwords_campaigns#set', as: :set
		end
		resources :adwords_campaign_groups do
			member do
				get 'set' => 'adwords_campaign_groups#set', as: :set
			end
		end
	end
end
resources :social_accounts
resources :api_accounts
resources :google_accounts
resources :industries
resources :invoices do
  member do
    get 'send_invoice' => 'invoices#send_invoice', as: :send_invoice
    get 'cancel_invoice' => 'invoices#cancel_invoice', as: :cancel_invoice
    get 'legend' => 'invoices#legend'
  end
  get 'update_invoices_info' => 'invoices#update_invoices_info', on: :collection
end
resources :youtube_channels do
  member do
    get 'set' => 'youtube_channels#set', as: :set
    get 'phone_usage' => 'youtube_channels#phone_usage', as: :phone_usage_youtube_channel
    post 'regenerate_channel_art', as: :regenerate_channel_art
  end
  resources :associated_websites do
    member do
      get 'set' => 'associated_websites#set', as: :set
    end
  end
end
get '/youtube_channels/tools/json_list' => 'youtube_channels#json_list', as: :youtube_channels_json_list
resources :google_account_activities
resources :youtube_videos do
  member do
    get 'set', as: :set_youtube_video
    post 'regenerate_video_thumbnail', as: :regenerate_video_thumbnail
    post 'reblend', as: :reblend
  end
	resources :youtube_video_annotations do
		member do
			get 'set' => 'youtube_video_annotations#set', as: :set
		end
	end
	resources :youtube_video_cards do
		member do
			get 'set' => 'youtube_video_cards#set', as: :set
		end
	end
	resources :call_to_action_overlays do
		member do
			get 'set' => 'call_to_action_overlays#set', as: :set
		end
	end
end
resources :youtube_video_search_phrases do
  member do
    post 'set_rank' => 'youtube_video_search_phrases#set_rank', as: :set_rank
  end
end
resources :client_landing_page_templates
scope :clients do
	get 'industry_association_with_donors' => 'clients#industry_association_with_donors'
	get 'tooltip_edit/:id' => 'clients#tooltip_edit', as: :tooltip_edit
	post 'tooltip_update/:id' => 'clients#tooltip_update', as: :tooltip_update
end
resources :clients do
  member do
    get 'assign_accounts_to_bot_server' => 'clients#assign_accounts_to_bot_server'
    get 'legend' => 'clients#legend'
    get 'assets' => 'clients#assets'
    get 'assets/images' => 'clients#assets_images'
  end
  get 'aae_templates'
	resources 'exclude_aae_templates', only: [:index, :create, :destroy], controller: "clients/exclude_aae_templates"

	post 'exclude_aae_templates/exclusion_settings' => 'clients/exclude_aae_templates#update_exclusion_settings', as: :template_exclusion_settings

	resource :rendering_settings, except: %w(index), controller: "clients/rendering_settings"
	resource :blending_settings, except: %w(index), controller: "clients/blending_settings"
	get 'subject_videos'
	get 'donor_videos'
	get 'image_tags/general' => 'clients#general_image_tags'
	get 'image_tags/source_videos' => 'clients#source_video_image_tags'
	post 'image_tags/general' => 'clients#update_general_image_tags'
	patch 'image_tags/general' => 'clients#update_general_image_tags'
	resource :image_tag_selection, only:[] do
		get 'client' => 'clients/image_selection_tags#edit_client_tags'
		post 'client' => 'clients/image_selection_tags#update_client_tags'
		get 'products' => 'clients/image_selection_tags#edit_products_tags'
		post 'products' => 'clients/image_selection_tags#update_products_tags'
		get 'source_videos' => 'clients/source_video_image_tag_selection#source_videos_tags'
		get "source_videos/:source_video_id" => 'clients/source_video_image_tag_selection#edit_source_video_tags'
		post "source_videos/:source_video_id" => 'clients/source_video_image_tag_selection#update'
		patch "source_videos/:source_video_id" => 'clients/source_video_image_tag_selection#update'
	end
	resources :donors, only: %w(index create update destroy), controller: 'clients/donors'
	resources :recipients, only: %w(index create update destroy), controller: 'clients/recipients'

	resources :products
	resources :client_landing_pages do
		member do
			get 'generate_landing_page' => 'client_landing_pages#generate_landing_page', as: :generate_landing_page
			get 'park_and_host' => 'client_landing_pages#park_and_host', as: :park_and_host
      get 'upload_index_file' => 'client_landing_pages#upload_index_file', as: :upload_index_file
		end
	end
	resources :representatives
  resources :contracts do
    member do
      get 'send_down_payment_invoice' => 'contracts#send_down_payment_invoice', as: :send_down_payment_invoice
    end
  end
	resources :email_accounts_setups
	resources :youtube_setups do
		member do
			get 'assign_accounts' => 'youtube_setups#assign_accounts', as: :assign_accounts
			get 'regenerate_channels_content' => 'youtube_setups#regenerate_channels_content', as: :regenerate_channels_content
      get 'generate_test_titles' => 'youtube_setups#generate_test_titles', as: :generate_test_titles
		end
    get 'tags_overview' => 'youtube_setups#tags_overview', on: :collection
    get 'descriptions_overview' => 'youtube_setups#descriptions_overview', on: :collection
	end
	resources :source_videos do
    member do
	    post :clone
    end
	end

	#TODO refactor using of hardcoded "video_workflow" prefix
	get 'video_workflow' => 'clients/video_workflow#index', as: :video_workflow
	post "video_workflow/blended_video_chunk/:id/approve/(:status)" 			=> 'clients/video_workflow#approve_blended_video_chunk', as: :approve_blended_video_chunk
	get "video_workflow/blended_video_chunk/:id/notes" 										=> 'clients/video_workflow#show_notes', as: :show_blended_video_chunk_notes
	post "video_workflow/blended_video_chunk/:id/notes" 									=> 'clients/video_workflow#update_notes', as: :update_blended_video_chunk_notes
	post "video_workflow/blended_videos/:id/approve/(:status)" 						=> 'clients/video_workflow#approve_blended_video', as: :approve_blended_video
	get "video_workflow/blended_videos/:id/video_chunks_block" 						=> 'clients/video_workflow#video_chunks_block', as: :video_chunks_block
	post "video_workflow/blended_video_chunks/:id/regenerate" 						=> 'clients/video_workflow#regenerate_video_segment', as: :regenerate_video_segment
	get "video_workflow/delayed_jobs/:video_set_id/:workflow_stage" 			=> "clients/video_workflow#delayed_jobs", as: :delayed_jobs
end

resources :blending_patterns do
	get 'add_blending_pattern_item', on: :collection
	get 'source_videos', on: :collection
	get 'products', on: :collection
end

post 'client_landing_pages/get_tamplate' => 'client_landing_pages#get_tamplate'
get 'client_landing_pages/tools/set' => 'client_landing_pages#set'
get 'client_landing_pages/tools/get_domain_token' => 'client_landing_pages#get_domain_token'
get 'client_landing_pages/tools/visitors_statistics' => 'client_landing_pages#visitors_statistics'

post '/youtube_setups/video_template_form' => 'youtube_setups#video_template_form'
post '/youtube_setups/video_template_list' => 'youtube_setups#video_template_list'
delete '/youtube_video_annotations/:id/' => 'youtube_video_annotations#destroy', as: :destroy_youtube_video_annotation
delete '/youtube_video_cards/:id/' => 'youtube_video_cards#destroy', as: :destroy_youtube_video_card

resources :watching_video_categories
resources :settings do
  get :fetch_value, on: :collection
end
resources :recovery_attempt_responses
resources :bot_servers do
  member do
    get 'turn_daily_activity' => 'bot_servers#turn_daily_activity', as: :turn_daily_activity
    get 'run_daily_activity' => 'bot_servers#run_daily_activity'
    get 'run_in_batch_daily_activity' => 'bot_servers#run_in_batch_daily_activity'
    get 'clear_daily_activity_queue' => 'bot_servers#clear_daily_activity_queue'
    get 'kill_zenno' => 'bot_servers#kill_zenno', as: :kill_zenno
    get 'start_zenno' => 'bot_servers#start_zenno', as: :start_zenno
  end
  get 'turn_off_activity_and_clear_queue' => 'bot_servers#turn_off_activity_and_clear_queue', on: :collection
  get 'enable_and_run' => 'bot_servers#enable_and_run', on: :collection
end
resources :phones do
	member do
		get 'legend' => 'phones#legend', as: :legend
		post 'park_did' => 'phones#park_did', as: :park_did
		delete 'cancel_voipms_did' => 'phones#cancel_voipms_did', as: :cancel_voipms_did
	end
end
get 'phones/tools/next_available_did' => 'phones#next_available_did', as: :next_available_did
get 'phones/tools/phone_number_for_account_creation' => 'phones#phone_number_for_account_creation', as: :phone_number_for_account_creation
get 'phones/tools/unusable' => 'phones#unusable', as: :unusable_phone

resources :phone_services
resources :phone_service_accounts do
	member do
		get 'order_dids' => 'phone_service_accounts#order_dids', as: :order_dids
		post 'finish_order_dids' => 'phone_service_accounts#finish_order_dids', as: :finish_order_dids
		get 'voipms_regions' => 'phone_service_accounts#voipms_regions', as: :voipms_regions
	end
  get 'sms_area_available_numbers' => 'phone_service_accounts#sms_area_available_numbers', on: :collection
end
resources :phone_providers
resources :phone_calls
resources :wordings, :except => :show
resources :text_chunks
resources :domains
resources :training_infos
resources :comments
resources :contact_people
resources :video_marketing_campaign_forms, only: [:index, :edit, :show, :update, :destroy]
resources :dealers do
  match 'save', via: :post, on: :collection
  member do
    get :add_similar
    post :send_invitation
  end
end
resources :ip_addresses do
  member do
    delete 'return_ip_address' => 'ip_addresses#return_ip_address', as: :return_ip_address
  end
end
resources :sent_emails, only: [:index, :new, :create]
resources :batches do
  member do
    get :refresh
  end
end
get 'ip_addresses/tools/next_available_ip_address' => 'ip_addresses#next_available_ip_address', as: :next_available_ip_address
get 'ip_addresses/tools/ip_address_for_account_creation' => 'ip_addresses#ip_address_for_account_creation', as: :ip_address_for_account_creation
get 'ip_addresses/tools/update_rating_statistics' => 'ip_addresses#update_rating_statistics', as: :update_rating_statistics

post '/wordings/add_batch' => 'wordings#add_batch', as: :add_batch_wording
post '/wordings/update_batch' => 'wordings#update_batch', as: :update_batch_wording
post '/wordings/resource_template' => 'wordings#resource_template', as: :resource_template_wording
get '/wordings/:id/legend' => 'wordings#legend', as: :legend_wording
post '/wordings/duplicates' => 'wordings#duplicates', as: :duplicates_wording
post '/wordings/history' => 'wordings#history', as: :history_wording
# GEO
get '/geo' => 'wordings#geo_index', as: :geo

get '/video_scripts' => 'video_scripts#index', as: :video_scripts
get '/video_parts/transitions' => 'video_part#transitions', as: :transitions
get '/video_parts/sales_pitches' => 'video_part#sales_pitches', as: :sales_pitches
post '/video_parts/transitions' => 'video_part#create_transition', as: :create_transition
post '/video_parts/create_sales_pitch' => 'video_part#create_sales_pitch', as: :create_sales_pitches
delete '/video_parts/:id' => 'video_part#destroy', as: :destroy_video_part

namespace :dashboard do
	namespace :video_workflow do
		resources :rendering_machines, only: %w(show index) do
		end
	end
end

# TODO refactor code since it is not secure
get '/source_videos/:id/thumbnail/remove' => 'source_videos#remove_thumbnail'
get '/google_accounts/generate_password' => 'google_accounts#generate_password'
post '/delayed_jobs/:id/relaunch' => 'delayed_josb#relaunch'
get '/google-api/authenticate' => 'google_api#authenticate', as: 'google_api_authenticate'
get '/google-api/callback' => 'google_api#callback', as: 'google_api_callback'
get '/admin/video_scripts/:id/body.json' => 'video_scripts#body_json', as: 'video_scripts_body_json'
get '/statistics/polygons/:country_code' => 'statistics#polygons'
get '/statistics/youtube_videos/uploads/:year/:month' => 'statistics#youtube_videos_monthly_statistics'
get '/statistics/youtube/:year/:month' => 'statistics#youtube_monthly_statistics', as: :youtube_monthly_statistics

get '/vkontakte/oauth' => 'vkontakte#oauth', as: :vkontakte_oauth
get '/vkontakte/oauth/callback' => 'vkontakte#oauth_callback'

get 'broadcasting/broadcast_streams', as: :broadcast_streams
get '/video_scripts/:id' => 'video_scripts#show', as: :video_script

get '/tools/password_generator' => 'google_accounts#password_generator', as: :password_generator

get '/host_machines' => 'host_machine#index', as: :host_machines
get '/host_machines/:id' => 'host_machine#show', as: :show_host_machine
get '/email_accounts/:id/legend' => 'email_accounts#legend', as: :legend_email_account
get '/email_accounts/tools/order' => 'email_accounts#order' , as: :order_email_accounts
post '/email_accounts/tools/execute_order' => 'email_accounts#execute_accounts_order', as: :execute_accounts_order
get '/email_accounts/tools/json_list' => 'email_accounts#json_list', as: :email_accounts_json_list
get '/email_accounts/tools/create_gmail_account' => 'email_accounts#create_gmail_account', as: :create_gmail_account

get '/google_account_activities/:id/touch' => 'google_account_activities#touch', as: :touch_google_account_activity
get '/google_account_activities/:id/recovery_attempt_answer' => 'google_account_activities#recovery_attempt_answer', as: :recovery_attempt_answer_google_account_activity
get '/google_account_activities/:id/recovery_attempt_response' => 'google_account_activities#recovery_attempt_response', as: :recovery_attempt_response_google_account_activity
get '/google_account_activities/:id/bot_action' => 'google_account_activities#bot_action', as: :bot_action_google_account_activity
get '/google_account_activities/tools/turn_recovery_attempt_activity' => 'google_account_activities#turn_recovery_attempt_activity', as: :turn_recovery_attempt_activity
get '/google_account_activities/:id/fetch_field' => 'google_account_activities#fetch_field', as: :fetch_field_google_account_activity
get '/google_account_activities/:id/phone_usage' => 'google_account_activities#phone_usage', as: :phone_usage_google_account_activity
get '/google_account_activities/:id/create_facebook_account' => 'google_account_activities#create_facebook_account', as: :create_facebook_account_google_account_activity
post '/google_account_activities/:id/add_youtube_strike' => 'google_account_activities#add_youtube_strike', as: :add_youtube_strike_google_account_activity
get '/google_account_activities/:id/create_google_plus_account' => 'google_account_activities#create_google_plus_account', as: :create_google_plus_account_google_account_activity
get '/google_account_activities/tools/rerun_youtube_business_channels_activity' => 'google_account_activities#rerun_youtube_business_channels_activity', as: :rerun_youtube_business_channels_activity
get '/google_account_activities/tools/rerun_youtube_videos_activity' => 'google_account_activities#rerun_youtube_videos_activity', as: :rerun_youtube_videos_activity
get '/google_account_activities/tools/rerun_youtube_videos_info_activity' => 'google_account_activities#rerun_youtube_videos_info_activity', as: :rerun_youtube_videos_info_activity
get '/google_account_activities/tools/rerun_youtube_video_annotations_activity' => 'google_account_activities#rerun_youtube_video_annotations_activity', as: :rerun_youtube_video_annotations_activity
get '/google_account_activities/tools/rerun_youtube_video_cards_activity' => 'google_account_activities#rerun_youtube_video_cards_activity', as: :rerun_youtube_video_cards_activity
get '/google_account_activities/tools/rerun_adwords_campaigns_activity' => 'google_account_activities#rerun_adwords_campaigns_activity', as: :rerun_adwords_campaigns_activity
get '/google_account_activities/tools/rerun_adwords_campaign_groups_activity' => 'google_account_activities#rerun_adwords_campaign_groups_activity', as: :rerun_adwords_campaign_groups_activity
get '/google_account_activities/tools/rerun_call_to_action_overlays_activity' => 'google_account_activities#rerun_call_to_action_overlays_activity', as: :rerun_call_to_action_overlays_activity
get '/google_account_activities/tools/rerun_recovery_process_activity' => 'google_account_activities#rerun_recovery_process_activity', as: :rerun_recovery_process_activity
get '/google_account_activities/tools/run_daily_activity' => 'google_account_activities#run_daily_activity', as: :run_daily_activity
get '/google_account_activities/tools/clear_daily_activity_queue' => 'google_account_activities#clear_daily_activity_queue', as: :clear_daily_activity_queue
post '/google_account_activities/:id/youtube_audio_library' => 'google_account_activities#youtube_audio_library'

get '/queue/:name' => 'queue#index', as: :index_queue
get '/queue/:name/:id/edit' => 'queue#edit', as: :edit_queue
get '/queue/:name/next_record' => 'queue#next_record', as: :next_record_queue
patch '/queue/:name/:id(.:format)' => 'queue#submit', as: :submit_queue
get '/queue/:name/tools/set_status' => 'queue#set_status', as: :set_status
get '/queue/:name/report_by_admin_users' => 'queue#report_by_admin_users', as: :report_by_admin_users_queue
post '/queue/:name/:id/process_again' => 'queue#process_again', as: :process_again_queue
get '/queue/:name/scheduled_jobs' => 'queue#scheduled_jobs', as: :scheduled_jobs_queue
post '/queue/:name/:id/unlock' => 'queue#unlock', as: :unlock_queue

get '/regions/(:country_id)' => 'geolocation#regions', as: :regions
get '/all_regions/(:country_id)' => 'geolocation#all_regions', as: :all_regions
get '/states' => 'geolocation#states', as: :states
post '/counties' => 'geolocation#counties', as: :counties
post '/cities' => 'geolocation#cities', as: :cities
get '/localities/(:region_id)' => 'geolocation#localities', as: :localities
post '/localities/top/(:localities_number)' => 'geolocation#top_localities', as: :top_localities
post '/localities/population_greater/(:population)' => 'geolocation#localities_with_population_greater', as: :localities_with_population_greater
get '/geolocation/zip_code/(:zip_code)' => 'geolocation#by_zip_code', as: :geolocation_by_zip_code
get '/geolocation/landmarks' => 'geolocation#landmarks', as: :geolocation_landmarks

get '/phone_usages' => 'phone_usages#index', as: :phone_usages
get '/phone_usages/last_sms_code' => 'phone_usages#last_sms_code', as: :last_sms_code_phone_usages

get '/industries/tools/json_list' => 'industries#json_list', as: :industries_json_list

get 'dashboard' => 'dashboard#index'
get 'dashboard/video_workflow' => 'dashboard#video_workflow', as: :dashboard_video_workflow
get '/dashboard/send_yt_stat_report' => 'dashboard#send_yt_stat_report', as: :dashboard_send_yt_stat_report
get '/bot_statistics_json' => 'dashboard#bot_statistics_json'
get '/server_stat_json' => 'dashboard#server_stat_json'
get '/server_hardware_json' => 'dashboard#server_hardware_json'

get 'delayed_jobs/relaunch'

match "/delayed_job" => DelayedJobWeb, :anchor => false, via: [:get, :post]
resources :youtube_video_search_ranks, only: [:index, :show]

scope :oauth do
	scope :soundcloud do
		get '' => 'oauth#soundcloud', as: :soundcloud
		get 'callback' => 'oauth#soundcloud_callback', as: :soundcloud_callback
		get 'refresh_token' => 'oauth#soundcloud_refresh_token', as: :soundcloud_refresh_token
	end
end
