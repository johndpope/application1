class Admin::Sandbox::YoutubeChannelController < Admin::BaseController
  include GenericCrudOperations
  include LocationHelper
  before_action :init_location_settings, only: [:edit]

  def initialize
    super
    init_settings({
      clazz: ::Sandbox::YoutubeChannel,
      large_form: true,
      view_folder: "admin/sandbox/youtube_channel",
      item_params: [
        :id,
        :sandbox_client_id,
        :title_subject_components_csv,
        :title_entity_components_csv,
        :title_descriptor_components_csv,
        :tags,
        :description_sep,
        :description,
        :location_id,
        :location_type,
        {
          :client_short_description_sep => [],
          :industry_short_description_sep => [],
          :location_short_description_sep => [],
          :other_short_description_sep => []
        }
      ],
      index_table_header: "Youtube channel",
      index_page_header: "Youtube channel"
    })
  end

  def init_location_settings
    @location_json = loc_json(@item.location)
  end
end
