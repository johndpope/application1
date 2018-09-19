class GoogleApiClient < ActiveRecord::Base	
	belongs_to :google_api_project, foreign_key: :google_api_project_id

	has_one :api_application, as: :app_item, dependent: :destroy
	
	def display_name
		return client_id
	end
end
