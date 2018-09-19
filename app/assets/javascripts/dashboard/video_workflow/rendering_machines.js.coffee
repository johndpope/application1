window.dashboard_video_workflow_rendering_machines_index = ->
	TIMEOUT = 30000
	sync_rendering_machines = ->
		yes_value = $('#yes_value').val()
		no_value = $('#no_value').val()
		texts = {'true':yes_value, 'false':no_value}
		classes = {'true':'success', 'false':'danger'}
		fields = ['in_watch_folder', 'in_queue', 'in_watch_folder_output',
			'is_accessible', 'is_active', 'today_video_sets',
			'today_video_chunks', 'total_video_sets', 'total_video_chunks',
			'number_of_generating_dynamic_projects', 'time_of_last_created_project']
		$.getJSON $('#dashboard_rendering_machines_json_url').val(), (json) ->
			for item in json.items
				do ->
					for f in fields
						do ->
							html = if f in ['is_accessible','is_active']
								"<div class='label label-#{classes["#{item[f]}"]}'>#{texts["#{item[f]}"]}</div>"
							else
								"#{item[f]}".replace(/null/, '?')
							$(".#{f}", "#row_rendering_machine_#{item.id}").html(html)
					percentage = "#{String(item['occupied_disk_space_percentage']).replace(/null/, '?')}"
					if percentage != '?'
						percentage = String("#{parseFloat(percentage).toFixed(1)}%")						
					$(".occupied_disk_space_percentage .progress-bar-span", "#row_rendering_machine_#{item.id}").
						text(percentage)
		.done ->
			setTimeout(sync_rendering_machines, TIMEOUT)

	setTimeout(sync_rendering_machines, TIMEOUT)
