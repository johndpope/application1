window.templates_aae_project_texts_correct_static_texts_index = ->
	$('#search_conditions select').select2
		allowClear: 'true',
		placeholder: 'Choose ...'
	$('#clear_search_conditions').click ->
		$('#search_conditions select, :hidden.form-control').val('').select2('val','')
		$('#search_conditions :text, [type="search"]').val('')
		$('#search_conditions textarea').text('')

	$('[name="templates_aae_project_text[corrected_value]"]').on 'change', ->
		f = $(this).closest('form')
		spinner = $('.saving-status-spinner',$(this).closest('tr'))
		spinner.show()
		$.post(
			f.attr('action')
			f.serialize()
		).always ->
			spinner.hide()

	$('[name="templates_aae_project_text[corrected_value]"]').each (index, el) ->
		$(el).textcounter
			type: "character",
			countSpaces: true,
			stopInputAtMaximum: true,
			max: parseInt($(this).attr('data-max-character-count')),
			counterText: "Characters Count: "

	$("[data-preview-template-sample=true],[data-preview-template-test=true]").each ->
		src = $(this).attr("href");
		content = '<video src="' + src + '" autoplay="true" type="video/mp4" controls="true" style="height: 540px; width: 960px" onloadstart="this.volume=0.35"></video>';
		$(this).fancybox({content: content, minHeight: 540, minWidth: 960});
