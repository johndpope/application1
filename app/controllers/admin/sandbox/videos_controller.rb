class Admin::Sandbox::VideosController < Admin::BaseController
	include GenericCrudOperations
	include LocationHelper
	before_action :init_location_settings, only: [:edit]
	def initialize
		super
    init_settings({
			clazz: ::Sandbox::Video,
		  view_folder: "admin/sandbox/videos",
			large_form: true,
			item_params: [:id, :title, :description, :sandbox_video_set_id, :source_video_id,
				:video_type, :templates_aae_project_id, :is_active, :is_approved, :notes, :thumb, :video, :duration, :locality_id, :location_id, :location_type],
			index_table_header: I18n.t('admin.sandbox.videos_list'),
			index_page_header: I18n.t('admin.sandbox.videos')
		})
  end

	def init_location_settings
		@location_json = loc_json(@item.location)
	end
end
