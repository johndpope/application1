class Admin::Sandbox::ClientCategoriesController < Admin::BaseController
	include GenericCrudOperations

	def initialize
    super
    init_settings({
			clazz: ::Sandbox::ClientCategory,
		  view_folder: "admin/sandbox/client_categories",
			item_params: [:id, :name],
			index_table_header: I18n.t('admin.sandbox.client_categories_list'),
			index_page_header: I18n.t('admin.sandbox.client_categories')
		})
  end
end
