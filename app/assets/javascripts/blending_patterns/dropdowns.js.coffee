$('#blending_pattern_source_video_id').select2
	placeholder: 'Choose',
	width: '100%',
	minimumInputLength: 0,
	allowClear: true,
	ajax:
		url: '/blending_patterns/source_videos.json',
		quietMillis: 300,
		data: (term, page) ->
			client_id = $('#blending_pattern_client_id').val()
			product_id = $('#blending_pattern_product_id').val()
			{ custom_title_cont: term, client_id_eq: client_id, product_id_eq: product_id, page: page, per_page: 10, sorts: 'custom_title asc' }
		results: (data, page) ->
			{
				results: $.map(data.items, (e) -> { id: e.id, text: e.custom_title }),
				more: (page * 10) < data.total
			}

$('#blending_pattern_product_id').select2
	placeholder: 'Choose',
	width: '100%',
	minimumInputLength: 0,
	allowClear: true,
	ajax:
		url: '/blending_patterns/products.json',
		quietMillis: 300,
		data: (term, page) ->
			client_id = $('#blending_pattern_client_id').val()
			{ name_cont: term, client_id_eq: client_id, page: page, per_page: 10, sorts: 'name asc' }
		results: (data, page) ->
			{
				results: $.map(data.items, (e) -> { id: e.id, text: e.name }),
				more: (page * 10) < data.total
			}

$('#blending_pattern_client_id').on 'change', ->
	$('#blending_pattern_product_id, #blending_pattern_source_video_id').select2("val", "")

$('#blending_pattern_product_id').on 'change', ->
	$('#blending_pattern_source_video_id').select2("val", "")

form_product_json = JSON.parse($('#form_product_json').val())
form_source_video_json = JSON.parse($('#form_source_video_json').val())
$('#blending_pattern_product_id').select2('data', {id: form_product_json.id, text: form_product_json.name}) if form_product_json?.id
$('#blending_pattern_source_video_id').select2('data', {id: form_source_video_json.id, text: form_source_video_json.custom_title}) if form_source_video_json?.id
