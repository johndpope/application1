class Admin::UserCompaniesController < Admin::BaseController
	include GenericCrudOperations

	def initialize
    super
    init_settings({
			clazz: ::AdminUserCompany,
		  view_folder: "admin/user_companies",
			item_params: [:id, :name],
			index_table_header: I18n.t('admin.user_companies_list'),
			index_page_header: I18n.t('admin.user_companies')
		})
  end

	def generate_password
		respond_to do |format|
			format.json{render json: {password: SecureRandom.hex(8)}}
		end
	end
end
