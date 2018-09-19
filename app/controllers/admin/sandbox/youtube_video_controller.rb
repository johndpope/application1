class Admin::Sandbox::YoutubeVideoController < Admin::BaseController
  include GenericCrudOperations
  include LocationHelper
  before_action :init_location_settings, only: [:edit]

  def initialize
    super
    init_settings({
      clazz: ::Sandbox::YoutubeVideo,
      large_form: true,
      view_folder: "admin/sandbox/youtube_video",
      item_params: [:id, :sandbox_client_id, :title_product_components_csv, :title_location_components, :title_subject_components_csv, :title_entity_components_csv, :descriptions_sep, :tags, :location_id, :location_type],
      index_table_header: "Sandbox Youtube videos",
      index_page_header: "Sandbox Youtube video"
    })
  end

  def init_location_settings
		@location_json = loc_json(@item.location)
	end
end
