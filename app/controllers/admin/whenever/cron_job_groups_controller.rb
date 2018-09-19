class Admin::Whenever::CronJobGroupsController < Admin::BaseController
	include GenericCrudOperations

	def initialize
		super
    init_settings({
			clazz: ::WheneverCronJobGroup,
		  view_folder: "admin/whenever/cron_job_groups",
			item_params: [:id, :name],
			index_table_header: I18n.t('admin.whenever_cron_job_groups_list'),
			index_page_header: I18n.t('admin.whenever_cron_job_groups')
		})
  end
end
