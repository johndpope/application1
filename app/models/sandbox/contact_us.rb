class Sandbox::ContactUs < ActiveRecord::Base
	belongs_to :sandbox_client, class_name: "Sandbox::Client", foreign_key: "sandbox_client_id"
	has_one :client, through: :sandbox_client
	validates :text, :name, :email, presence: true
  validates_format_of :email, :with => /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i

  class << self
    def by_name (name)
      return all unless name.present?
      # where('contact_us.name = ?', name.strip)
      where('lower(sandbox_contact_us.name) like ?', "%#{name.downcase}%")
    end

    def by_client_name (client_name)
      return all unless client_name.present?
      where('lower(clients.name) like ?', "%#{client_name.downcase}%")
    end

    def by_email (email)
      return all unless email.present?
      where('lower(sandbox_contact_us.email) like ?', "%#{email.downcase}%")
    end

    def by_phone (phone)
      return all unless phone.present?
      where('lower(sandbox_contact_us.phone) like ?', "%#{phone.downcase}%")
    end
  end
end
