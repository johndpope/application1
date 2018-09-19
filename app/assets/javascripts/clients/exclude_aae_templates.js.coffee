fancybox_settings = {
	prevEffect: 'none',
	nextEffect: 'none',
	closeBtn: false,
	helpers: {
		title: { type: 'inside' },
		buttons: {}
	}
}

window.clients_exclude_aae_templates_index = ->
	$('.livepreview').livePreview({position: 'right'});
	$('.aae-project-thumbnail').fancybox(fancybox_settings);	
