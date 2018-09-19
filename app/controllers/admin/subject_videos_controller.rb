class Admin::SubjectVideosController < Admin::BaseController
	include GenericCrudOperations

	def initialize
    super
    init_settings({
			clazz: ::SourceVideo,
		  view_folder: "admin/subject_videos",
			item_params: [:id, :custom_title, :client_id, :is_active],
			index_table_header: I18n.t('admin.source_videos_list'),
			index_page_header: I18n.t('admin.source_videos'),
			large_form: true,
			index_json_conversion_options: {only: [:id, :custom_title]}
		})
  end
end
