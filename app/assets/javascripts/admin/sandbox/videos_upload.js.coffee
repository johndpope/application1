window.admin_sandbox_videos_upload_index = ->
	# Initialize the jQuery File Upload widget:
	$('#fileupload').fileupload
		autoUpload: false
	.on 'fileuploadsubmit', (e, data) ->
    form_data = {video_set_id: $('#video_set_id').val()}
    form_data['reusable'] = $('#reusable').val()
    form_data['broadcaster_property'] = $('#broadcaster_property').val()
    data.formData = form_data

	$('#video_set_id').select2
		allowClear: true,
		placeholder: "Choose ..."
