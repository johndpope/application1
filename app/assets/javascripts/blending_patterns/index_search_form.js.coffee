$('#q_source_video_id_eq').select2
	placeholder: 'Choose',
	width: '100%',
	minimumInputLength: 0,
	allowClear: true,
	ajax:
		url: '/blending_patterns/source_videos.json',
		quietMillis: 300,
		data: (term, page) ->
			client_id = $('#q_client_id_eq').val()
			product_id = $('#q_product_id_eq').val()
			{ custom_title_cont: term, client_id_eq: client_id, product_id_eq: product_id, page: page, per_page: 10, sorts: 'custom_title asc' }
		results: (data, page) ->
			{
				results: $.map(data.items, (e) -> { id: e.id, text: e.custom_title }),
				more: (page * 10) < data.total
			}

$('#q_product_id_eq').select2
	placeholder: 'Choose',
	width: '100%',
	minimumInputLength: 0,
	allowClear: true,
	ajax:
		url: '/blending_patterns/products.json',
		quietMillis: 300,
		data: (term, page) ->
			client_id = $('#q_client_id_eq').val()
			{ name_cont: term, client_id_eq: client_id, page: page, per_page: 10, sorts: 'name asc' }
		results: (data, page) ->
			{
				results: $.map(data.items, (e) -> { id: e.id, text: e.name }),
				more: (page * 10) < data.total
			}

$('#q_client_id_eq').on 'change', ->
	$('#q_product_id_eq, #q_source_video_id_eq').select2("val", "")

$('#q_product_id_eq').on 'change', ->
	$('#q_source_video_id_eq').select2("val", "")

search_form_product_json = JSON.parse($('#search_form_product_json').val())
search_form_source_video_json = JSON.parse($('#search_form_source_video_json').val())
$('#q_product_id_eq').select2('data', {id: search_form_product_json.id, text: search_form_product_json.name}) if search_form_product_json?.id
$('#q_source_video_id_eq').select2('data', {id: search_form_source_video_json.id, text: search_form_source_video_json.custom_title}) if search_form_source_video_json?.id
