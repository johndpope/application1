window.admin_sandbox_video_campaigns_index = ->
	$('#q_source_video_id_eq').select2
		placeholder: 'Choose',
		width: '100%',
		minimumInputLength: 0,
		allowClear: true,
		ajax:
			url: '/admin/subject_videos.json',
			quietMillis: 300,
			data: (term, page) ->
				{
					"q[client_id_eq]": $('#q_client_id_eq').val(),
					page: page,
					per_page: 10
				}
			results: (data, page) ->
				{
					results: $.map(data.items, (e) -> { id: e.id, text: e.custom_title }),
					more: (page * 10) < data.total
				}
	current_source_video_json = JSON.parse($('#current_source_video_json').val())
	$('#q_source_video_id_eq').select2('data', {id: current_source_video_json.id, text: current_source_video_json.custom_title}) if current_source_video_json? && current_source_video_json?.custom_title
