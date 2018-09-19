class Dashboard::VideoWorkflow::RenderingMachinesController < ApplicationController
	include DataPage
	include GenericCrudOperations

	def initialize
		super
		init_settings({
			clazz: ::RenderingMachine,
			index_json_conversion_options: {only: [:id,
				:name,
				:ip,
				:in_watch_folder,
				:in_watch_folder_output,
				:in_queue,
				:is_active,
				:is_accessible],
				methods: [:today_video_sets,
					:total_video_sets,
					:today_video_chunks,
					:total_video_chunks,
					:number_of_generating_dynamic_projects,
					:time_of_last_created_project,
					:occupied_disk_space_percentage]},
			view_folder: "dashboard/video_workflow/rendering_machines",
			large_form: true,
			show_action_bar: false,
			index_table_header: I18n.t('vmware_virtual_machines_list'),
			index_page_header: I18n.t('vmware_virtual_machines'),
			stylesheets: %w(progress-bar)
		})
  end
end
