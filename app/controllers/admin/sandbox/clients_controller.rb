class Admin::Sandbox::ClientsController < Admin::BaseController
	include GenericCrudOperations
	SEARCH_IMAGES_COUNT_DEFAULT_LIMIT = 10

	before_action :set_attachment, only: [:update]
	after_action :set_attachment, only: [:create]

	def initialize
    super
    init_settings({
			clazz: ::Sandbox::Client,
		  view_folder: "admin/sandbox/clients",
			item_params: [:id, :client_category_id, :client_id, :is_active, :description, :logo, :background_image, :subject_image],
			index_table_header: I18n.t('admin.sandbox.clients_list'),
			index_page_header: I18n.t('admin.sandbox.clients'),
			large_form: true,
			javascripts: %w(holderr.min)
		})
  end

	def browse
		@image_type = params["image_type"]
	end

	def search
		search = { total: 0, items: [] }
		params[:limit] = SEARCH_IMAGES_COUNT_DEFAULT_LIMIT unless params[:limit].present?

		options = params.merge(
			{q: params[:q], page: params[:page], limit: params[:limit]}
		)
		search = Artifacts::Image.list(options)

		@images = Kaminari.paginate_array(
			search[:items],
			total_count: search[:total]
		).page(params[:page]).per(params[:limit])
		@total_count = search[:total]
	end

	protected
		def set_attachment
			%w(logo background_image subject_image).each do |attachment|
				eval("@item.#{attachment} = File.open(params[:sandbox_client]['#{attachment}_path'.to_sym])") unless params[:sandbox_client]["#{attachment}_path".to_sym].blank?
			end
			@item.save
		end

end
