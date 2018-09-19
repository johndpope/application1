window.templates_dynamic_aae_projects_index = ->
	$(".preview-video").each ->
		src = $(this).attr("href");
		content = '<video src="' + src + '" autoplay="true" type="video/mp4" controls="true" style="height: 540px; width: 960px" onloadstart="this.volume=0.35"></video>';
		$(this).fancybox({content: content, minHeight: 540, minWidth: 960});
