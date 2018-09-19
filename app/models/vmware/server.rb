class Vmware::Server < ActiveRecord::Base
	validates_presence_of :order_nr, :ip, :user, :password
	validates_uniqueness_of :order_nr, :ip

	has_many :virtual_machines, class_name: "RenderingMachine"

	def name
		server_order_nr = self.order_nr.blank? ? '-' : self.order_nr

		"Server #{server_order_nr}"
	end
end
