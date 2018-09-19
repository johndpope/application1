window.artifacts_images_report_by_industries = ->
  $('select').select2()
  $('.numeric').on 'keypress', (e) ->
    if (e.which != 8 && e.which != 0 && (e.which < 48 || e.which > 57))
      return false

  $('#limit').on 'change', ->
		value = $('#limit').val()
		if (value < 1)
      $('#limit').val(1)


	th = $('#' + $('#filter_order').val() + '-th')

	if (th != 'undefined')
    th.addClass('sort_' + $('#filter_order_type').val())

	$('#industries_table th').on 'click', ->
		if ($(this).hasClass('sort'))
			data_field = $(this).attr('data-field')
			if ($(this).hasClass('sort_asc'))
				$('#industries_table th').removeClass('sort_asc').removeClass('sort_desc')
				$(this).removeClass('sort_asc').addClass('sort_desc')
				$('#filter_order_type').select2('val', 'desc')
			else
				$('#industries_table th').removeClass('sort_asc').removeClass('sort_desc')
				$(this).removeClass('sort_desc').addClass('sort_asc')
				$('#filter_order_type').select2('val', 'asc')
			$('#filter_order').select2('val', data_field)
			$('#filters_form').submit()
