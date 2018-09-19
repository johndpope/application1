class Admin::MakesAndModels::ModelsController < Admin::BaseController
	include GenericCrudOperations

	def initialize
		super
    init_settings({
			clazz: ::Model,
		  view_folder: "admin/makes_and_models/models",
			large_form: true,
			item_params: [:id, :product_category_id, :make_id, :name],
			index_table_header: I18n.t('admin.models_list'),
			index_page_header: I18n.t('admin.models')
		})
  end
end
