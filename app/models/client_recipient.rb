class ClientRecipient < ActiveRecord::Base
	belongs_to :client
	belongs_to :recipient, class_name: 'Client', foreign_key: 'recipient_id'
end
