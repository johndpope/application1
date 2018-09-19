class ApiApplication < ActiveRecord::Base
	belongs_to :app_item, polymorphic: true
	belongs_to :host_machine

	has_many :email_account_api_applications
	has_many :email_accounts, :through => :email_account_api_applications

	extend Enumerize

	enumerize :application_type, in: {:soundcloud => 1, :iconfinder => 2, :jamendo => 3}, scope: :having_application_type

	validates :application_type, presence: true

	def self.has_api?(application_type)
		ApiApplication.having_application_type(application_type).exists?
	end
end
