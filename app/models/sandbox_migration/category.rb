module SandboxMigration
	class Category < ActiveRecord::Base
		use_connection_ninja(:sandbox)

		validates_presence_of :name
		validates_uniqueness_of :name

		before_save :set_slug

		has_many :clients

		private
		def set_slug
			self.slug = self.name.to_url
		end
	end
end
