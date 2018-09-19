$('#sandbox_video_campaign_sandbox_client_id').select2
	placeholder: 'Choose',
	width: '100%',
	minimumInputLength: 0,
	allowClear: true,
	ajax:
		url: '/admin/sandbox/video_campaigns/sandbox_clients.json',
		quietMillis: 300,
		data: (term, page) ->
			{ name_or_code_cont: term, page: page, per_page: 10 }
		results: (data, page) ->
			{
				results: $.map(data.items, (e) -> { id: e.id, text: e.client_name, client_id: 1 }),
				more: (page * 10) < data.total
			}
$('#sandbox_video_campaign_source_video_id').select2
	placeholder: 'Choose',
	width: '100%',
	minimumInputLength: 0,
	allowClear: true,
	ajax:
		url: '/admin/sandbox/video_campaigns/source_videos.json',
		quietMillis: 300,
		data: (term, page) ->
			{
				sandbox_client_id: $('#sandbox_video_campaign_sandbox_client_id').val(),
				name_or_code_cont: term,
				page: page,
				per_page: 10
			}
		results: (data, page) ->
			{
				results: $.map(data.items, (e) -> { id: e.id, text: e.custom_title }),
				more: (page * 10) < data.total
			}
$('#sandbox_video_campaign_source_video_id').change ->
	title_box = $('#sandbox_video_campaign_title'); title_box.val($(this).select2('data').text)

sandbox_client_json = JSON.parse($('#sandbox_client_json').val())
source_video_json = JSON.parse($('#source_video_json').val())
$('#sandbox_video_campaign_sandbox_client_id').select2('data', {id: sandbox_client_json.id, text: sandbox_client_json.client.name}) if sandbox_client_json? && sandbox_client_json?.client?.name
$('#sandbox_video_campaign_source_video_id').select2('data', {id: source_video_json.id, text: source_video_json.custom_title}) if source_video_json?.id && source_video_json.custom_title
