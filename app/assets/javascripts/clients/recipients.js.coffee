window.clients_recipients_index = ->
	options = {placeholder: 'Choose ...', allowClear: true}
	$('select').select2(options)

	$("body").on "nested:fieldAdded", '#recipients', (event) ->
		$('select',event.field).select2(options)
