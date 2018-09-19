class Admin::Vmware::ServersController < Admin::BaseController
	include GenericCrudOperations

	def initialize
    super
    init_settings({
			clazz: ::Vmware::Server,
		  view_folder: "admin/vmware/servers",
			item_params: [:id, :order_nr, :user, :password, :ip, ],
			index_table_header: I18n.t('vmware_servers_list'),
			index_page_header: I18n.t('vmware_servers'),
			large_form: true,
			index_json_conversion_options: {only: [:id, :name]},
		})
  end
end
