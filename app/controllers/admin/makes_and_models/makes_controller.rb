class Admin::MakesAndModels::MakesController < Admin::BaseController
	include GenericCrudOperations

	def initialize
		super
    init_settings({
			clazz: ::Make,
		  view_folder: "admin/makes_and_models/makes",
			large_form: true,
			item_params: [:id, :product_category_id, :name],
			index_table_header: I18n.t('admin.makes_list'),
			index_page_header: I18n.t('admin.makes')
		})
  end
end
