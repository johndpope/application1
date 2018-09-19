window.artifacts_images_report_by_localities =->
  $('.numeric').on 'keypress', (e) ->
    if (e.which != 8 && e.which != 0 && (e.which < 48 || e.which > 57))
      return false
  # $('#filters_form').preventDefault();

  $('#images_count_limit').on 'change', ->
    value = $('#images_count_limit').val()
    if (value < 0)
      $('#images_count_limit').val(0)

  $('#limit').on 'change', ->
		value = $('#limit').val()
		if (value < 1)
      $('#limit').val(1)

  $('.select-box').select2
    placeholder: 'Choose ...',
    width: '100%',
    minimumInputLength: 0,
    allowClear: true

  $('.locality-type-select').select2
    width: '100%',
    minimumInputLength: 0

  $('.locality-type-select').on 'change', ->
    $(this).closest('form').submit()

  $('.edit_locality').submit ->
    form = $(this)
    $.ajax
      url: $(this).attr('action'),
      type: 'post',
      data : $(this).serialize(),
      success: ->
        form.parent().effect('highlight', { color: 'green' }, 2000)
      error: ->
        form.parent().effect('highlight', { color: 'red' }, 3000)
    return false

  $('#country').select2
    placeholder: 'Choose',
    width: '100%',
    minimumInputLength: 0,
    allowClear: false,
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
    initSelection: (element, callback) ->
      data = {id: element.val(), text: element.data('name')}
      callback(data)

  $('#region2').select2
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
          country_id_eq: $('#country').val(),
          parent_id_eq: $('#region1').val(),
          page: page,
          per_page: 10,
          sorts: 'name asc'
        }
      results: (data, page) ->
        {
          results: $.map(data.items, (e) -> { id: e.id, text: e.name }),
          more: (page * 10) < data.total
        }
    initSelection: (element, callback) ->
      data = {id: element.val(), text: element.data('name')}
      callback(data)

  $('#city').select2
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
    initSelection: (element, callback) ->
      data = {id: element.val(), text: element.data('name')}
      callback(data)

  $('#country').on 'change', ->
    $('#region1').select2('val', '')
    $('#city').select2('val', '')

  $('#region1').on 'change', ->
    $('#city').select2('val', '')

  $('#city').on 'change', ->
    if (locality_id = $(this).val())
      $.get "/geobase/localities.json?id_eq=#{locality_id}", (data) ->
        locality = data.items[0]
        country = locality.country
        region1 = locality.primary_region
        $('#country').select2('data', { id: country.id, text: country.name })
        $('#region1').select2('data', { id: region1.id, text: region1.name })

	order_by = $('#filter_order')
	order_type = $('#filter_order_type')
	th = $('#' + order_by.val() + '-th')

	if (th != 'undefined')
    th.addClass('sort_' + order_type.val())

	$('#cities_table th').on 'click', ->
		if ($(this).hasClass('sort'))
			data_field = $(this).attr('data-field')
			if ($(this).hasClass('sort_asc'))
				$('#cities_table th').removeClass('sort_asc').removeClass('sort_desc')
				$(this).removeClass('sort_asc').addClass('sort_desc')
				order_type.select2('val', 'desc')
			else
				$('#cities_table th').removeClass('sort_asc').removeClass('sort_desc')
				$(this).removeClass('sort_desc').addClass('sort_asc')
				order_type.select2('val', 'asc')
			order_by.select2('val', data_field)
			$('#filters_form').submit()
