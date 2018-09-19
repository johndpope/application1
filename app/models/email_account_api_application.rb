class EmailAccountApiApplication < ActiveRecord::Base
	belongs_to :api_application
	belongs_to :email_account
end
