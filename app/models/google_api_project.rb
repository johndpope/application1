class GoogleApiProject < ActiveRecord::Base
	belongs_to :google_account, foreign_key: :google_account_id
	has_many :google_api_clients

	def display_name
		return name
	end
end
