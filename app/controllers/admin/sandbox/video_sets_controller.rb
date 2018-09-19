class Admin::Sandbox::VideoSetsController < Admin::BaseController
	include GenericCrudOperations

	def initialize
		super
    init_settings({
			clazz: ::Sandbox::VideoSet,
		  view_folder: "admin/sandbox/video_sets",
			large_form: true,
			item_params: [:id, :title, :sandbox_client_id, :is_active, :thumb, :order_nr, :blended_sample],
			index_table_header: I18n.t('admin.sandbox.video_sets_list'),
			index_page_header: I18n.t('admin.sandbox.video_sets'),
			index_json_conversion_options: {only: [:id, :title], include: {client: {only: [:id, :name]}}}
		})
  end
end
