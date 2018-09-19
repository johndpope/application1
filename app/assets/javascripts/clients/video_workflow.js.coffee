window.clients_video_workflow_index = ->
	$('body').popover({
	  selector: '[data-toggle="popover"]',
		trigger: 'hover'
	});

	$('.livepreview').livePreview({position: 'right'});
	$(".preview-video").each ->
		src = $(this).attr("href");
		content = '<video src="' + src + '" autoplay="true" type="video/mp4" controls="true" style="height: 540px; width: 960px" onloadstart="this.volume=0.35"></video>';
		$(this).fancybox({content: content, minHeight: 540, minWidth: 960});
	$('[data-widget="collapse"]').click ->
		container = $(this).closest('#blended_video_chunks_details')
		if(container.hasClass('collapsed-box') && $('.video-chunks',container).length == 0)
			$('.box-body',container).load container.data('url')
