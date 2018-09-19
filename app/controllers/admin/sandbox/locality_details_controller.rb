class Admin::Sandbox::LocalityDetailsController < Admin::BaseController
	include GenericCrudOperations

	def initialize
		super
    init_settings({
			clazz: ::Sandbox::LocalityDetails,
			large_form: true,
		  view_folder: "admin/sandbox/locality_details",
			item_params: [:id, :locality_id, :default_background_image, :active_background_image],
			index_table_header: I18n.t('admin.sandbox.locality_details_list'),
			index_page_header: I18n.t('admin.sandbox.locality_details')
		})
  end
end
