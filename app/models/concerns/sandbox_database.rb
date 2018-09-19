module SandboxDatabase
	class ContactUs < ActiveRecord::Base
		use_connection_ninja(:sandbox)

		belongs_to :client

		class << self
			def by_name (name)
				return all unless name.present?
				# where('contact_us.name = ?', name.strip)
				where('lower(contact_us.name) like ?', "%#{name.downcase}%")
			end

			def by_client_name (client_name)
				return all unless client_name.present?
				where('lower(clients.name) like ?', "%#{client_name.downcase}%")
			end

			def by_email (email)
				return all unless email.present?
				where('lower(contact_us.email) like ?', "%#{email.downcase}%")
			end

			def by_phone (phone)
				return all unless phone.present?
				where('lower(contact_us.phone) like ?', "%#{phone.downcase}%")
			end
		end
	end

	class Client < ActiveRecord::Base
		use_connection_ninja(:sandbox)

		has_many :contact_us
	end
end
