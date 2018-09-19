class Admin::Sandbox::VideoCampaignVideoStagesController < Admin::BaseController
	include GenericCrudOperations

	def initialize
		super
    init_settings({
			clazz: ::Sandbox::VideoCampaignVideoStage,
			large_form: true,
		  view_folder: "admin/sandbox/video_campaign_video_stages",
			item_params: [:id, :title, :description, :video_campaign_id, :is_active,
				:tags, :thumbnail, :month_nr, :locality_id, :likes, :dislikes, :shares, :comments,
				:position, :views],
			index_table_header: I18n.t('admin.sandbox.video_campaign_video_stages_list'),
			index_page_header: I18n.t('admin.sandbox.video_campaign_video_stages')
		})
  end
end
