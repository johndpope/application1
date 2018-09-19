class Admin::Whenever::CronJobsController < Admin::BaseController
	include GenericCrudOperations

	def initialize
		super
    init_settings({
			clazz: ::WheneverCronJob,
		  view_folder: "admin/whenever/cron_jobs",
			large_form: true,
			item_params: [:id, :description, :period, :at, :job_group_id, :job_type, :job_value, :is_active],
			index_table_header: I18n.t('admin.whenever_cron_jobs_list'),
			index_page_header: I18n.t('admin.whenever_cron_jobs')
		})
  end
end
