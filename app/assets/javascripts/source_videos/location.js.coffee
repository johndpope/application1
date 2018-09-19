$('.select2').select2
	placeholder: 'Choose ...',
	width: '100%',
	minimumInputLength: 0,
	allowClear: true

$('#country_id').select2
	placeholder: 'Choose',
	width: '100%',
	minimumInputLength: 0,
	allowClear: true,
	ajax:
		url: '/geobase/countries.json',
		quietMillis: 300,
		data: (term, page) ->
			{ name_or_code_cont: term, page: page, per_page: 10, sorts: 'name asc' }
		results: (data, page) ->
			{
				results: $.map(data.items, (e) -> { id: e.id, text: e.name }),
				more: (page * 10) < data.total
			}
	initSelection: (element, callback) ->
		data = {id: element.val(), text: element.data('name')}
		callback(data)

$('#region1_id').select2
	placeholder: 'Choose',
	width: '100%',
	minimumInputLength: 0,
	allowClear: true,
	ajax:
		url: '/geobase/regions.json',
		quietMillis: 300,
		data: (term, page) ->
			{
				name_or_code_cont: term,
				level_eq: 1,
				country_id_eq: $('#country_id').val(),
				page: page,
				per_page: 10,
				sorts: 'name asc'
			}
		results: (data, page) ->
			{
				results: $.map(data.items, (e) -> { id: e.id, text: e.name }),
				more: (page * 10) < data.total
			}

$('#region2_id').select2
	placeholder: 'Choose',
	width: '100%',
	minimumInputLength: 0,
	allowClear: true,
	ajax:
		url: '/geobase/regions.json',
		quietMillis: 300,
		data: (term, page) ->
			{
				name_or_code_cont: term,
				level_eq: 2,
				country_id_eq: $('#country_id').val(),
				parent_id_eq: $('#region1_id').val(),
				page: page,
				per_page: 10,
				sorts: 'name asc'
			}
		results: (data, page) ->
			{
				results: $.map(data.items, (e) -> { id: e.id, text: e.name }),
				more: (page * 10) < data.total
			}

$('#locality_id').select2
	placeholder: 'Choose',
	width: '100%',
	minimumInputLength: 0,
	allowClear: true,
	ajax:
		url: '/geobase/localities.json',
		quietMillis: 300,
		data: (term, page) ->
			{
				name_or_code_cont: term,
				country_id_eq: $('#country_id').val(),
				primary_region_id_eq: $('#region1_id').val(),
				page: page,
				per_page: 10,
				sorts: ['population desc', 'name asc']
			}
		results: (data, page) ->
			{
				results: $.map(data.items, (e) -> { id: e.id, text: e.name }),
				more: (page * 10) < data.total
			}
$('#locality_id').on 'change', ->
	if (locality_id = $(this).val())
		$.get "/geobase/localities.json?id_eq=#{locality_id}", (data) ->
			locality = data.items[0]
			country = locality.country
			region1 = locality.primary_region
			region2 = locality.secondary_regions[0]
			$('#country_id').select2('data', { id: country.id, text: country.name })
			$('#region1_id').select2('data', { id: region1.id, text: region1.name })
			$('#region2_id').select2('data', { id: region2.id, text: region2.name })

if(location_json = $('#location_json').val())
	json = JSON.parse(location_json)
	$('#country_id').select2('data', { id: json.country.id, text: json.country.name }) if json.country.name? && json.country.id?
	$('#region1_id').select2('data', { id: json.region1.id, text: json.region1.name }) if json.region1.name && json.region1.id?
	$('#region2_id').select2('data', { id: json.region2.id, text: json.region2.name }) if json.region2.name && json.region2.id?
	$('#locality_id').select2('data', { id: json.locality.id, text: json.locality.name }) if json.locality.name && json.locality.id?
