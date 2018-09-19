class Admin::RenderingMachinesController < Admin::BaseController
	include GenericCrudOperations

	before_action :set_vmware_virtual_machine_names, only: %w(index create update new edit)
	before_action :set_vmware_server_id_options, only: %w(new edit create update)

	def initialize
    super
    init_settings({
			clazz: ::RenderingMachine,
		  view_folder: "admin/rendering_machines",
			item_params: [:id, :order_nr, :user, :password, :ip, :vmware_server_id, :is_active, :is_test],
			index_table_header: I18n.t('vmware_virtual_machines_list'),
			index_page_header: I18n.t('vmware_virtual_machines'),
			large_form: true
		})
  end

	private
		def set_vmware_virtual_machine_names
			@vmware_virtual_machine_names = RenderingMachine.
				joins("LEFT OUTER JOIN vmware_servers ON rendering_machines.vmware_server_id = vmware_servers.id").
				order(:id).
				map{|vm|{vm.id => vm.name}}.
				inject(:merge)
		end

		def set_vmware_server_id_options
			@vmware_server_id_options = ::Vmware::Server.order(:order_nr).map{|s|[s.name, s.id]}
		end
end
