window.dashboard_index = ->
	TIMEOUT = 60000
	sync_video_workflow_box = ->
		video_workflow_box = $('#video_workflow_box')
		$.getJSON video_workflow_box.data('url'), (json) ->
			for item in ['clients','subject_videos','video_sets']
				do ->
					$("##{item}_undone").html(json.undone_items[item])
			for item in ["Templates::DynamicAaeProjects::CreateDynamicAaeProjectJob","Templates::DynamicAaeProjects::TakeOutputVideoJob","Templates::DynamicAaeProjects::RemoveOutputVideoFromRenderingMachineJob","BlendedVideos::BlendVideoSetJob","Youtube::CreateYoutubeVideoJob","Youtube::GenerateThumbnailForCreatedYoutubeVideoJob"]
				do ->
					tr = $("##{item.replace(/::/g,'')}")
					$('.failed',tr).html(json.delayed_jobs[item]['failed'])
					$('.total',tr).html(json.delayed_jobs[item]['total'])
		.done ->
			setTimeout(sync_video_workflow_box, TIMEOUT)

	sync_video_workflow_box()
