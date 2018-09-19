window.clients_donors_index = ->
	options = {placeholder: 'Choose ...', allowClear: true}
	$('select').select2(options)

	$("body").on "nested:fieldAdded", '#donors', (event) ->
		$('select',event.field).select2(options)
