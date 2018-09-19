class Admin::MakesAndModels::ProductCategoriesController < Admin::BaseController
	include GenericCrudOperations

	def initialize
		super
    init_settings({
			clazz: ::ProductCategory,
		  view_folder: "admin/makes_and_models/product_categories",
			item_params: [:id, :name, :parent_id],
			index_table_header: I18n.t('admin.product_categories_list'),
			index_page_header: I18n.t('admin.product_categories')
		})
  end
end
