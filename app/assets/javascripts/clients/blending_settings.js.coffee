window.clients_blending_settings_show = ->
	genres_blacklist_block = $('#genres_blacklist')
	genres_blacklist_field = $("[name='client[blending_settings_attributes][soundtrack_genre_blacklist]']")
	genres_blacklist_block.on 'change', ->
		checked_items = $(':checkbox:checked', genres_blacklist_block)
		genres_blacklist_field_val = "{#{($(item).attr('value') for item in checked_items).join(',')}}"
		genres_blacklist_field.val(genres_blacklist_field_val)
