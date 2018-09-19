class Admin::UsersController < Admin::BaseController
	include GenericCrudOperations

	  @admin_user = AdminUser.includes(:country)
		.references(:country)

	def initialize
    super
    init_settings({
			clazz: ::AdminUser,
		  view_folder: "admin/users",
			item_params: [:id, :first_name, :last_name, :email, :roles, :title, :company, :country_id, :address_1, :address_2, :password, :phones_csv, :admin_user_company_id],
			index_table_header: I18n.t('admin.users_list'),
			index_page_header: I18n.t('admin.users')
		})
  end

	def generate_password
		respond_to do |format|
			format.json{render json: {password: SecureRandom.hex(8)}}
		end
	end
end
