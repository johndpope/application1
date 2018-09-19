$('#country').select2
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
$('#region1').select2
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
				country_id_eq: $('#country').val(),
				page: page,
				per_page: 10,
				sorts: 'name asc'
			}
		results: (data, page) ->
			{
				results: $.map(data.items, (e) -> { id: e.id, text: e.name }),
				more: (page * 10) < data.total
			}
$('#region1').select2
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
				country_id_eq: $('#country').val(),
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
				country_id_eq: $('#country').val(),
				primary_region_id_eq: $('#region1').val(),
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
			$('#country').select2('data', { id: country.id, text: country.name })
			$('#region1').select2('data', { id: region1.id, text: region1.name })

locality_json = JSON.parse($('#locality_json').val())

$('#locality_id').select2('data', {id: locality_json.id, text: locality_json.name}) if locality_json?.id
$('#region1').select2('data', {id: locality_json.primary_region.id, text: locality_json.primary_region.name}) if locality_json?.primary_region?.id
$('#country').select2('data', {id: locality_json.primary_region.country.id, text: locality_json.primary_region.country.name}) if locality_json?.primary_region?.country?.id
