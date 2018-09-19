window.sandbox_sandbox_clients_show = ->
	$('#btn_spin').on 'click', ->
		window.location.href = $('#locality_campaign_video_sets option:selected').attr('data-url');
