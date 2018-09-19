class SentEmail < ActiveRecord::Base
  belongs_to :admin_user
  belongs_to :resource, polymorphic: true
  validates :sender, :receiver, :subject, :body, presence: true
  EMAIL_TYPES = {
		'First Dealer Sign Up Invitation' => 1
	}
  extend Enumerize
	enumerize :email_type, :in => EMAIL_TYPES
end
