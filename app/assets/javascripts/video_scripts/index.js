$(function(){
	$(document).on('ready page:load', function () {
	  	var preview_modal = $('#preview_modal')
		var path = $('#video_script_path').val()

		$('.preview-script').bind('click',function(){
			preview_modal.modal()
		})

		$('.preview-script-notes').bind('click', function(){
			preview_modal.modal()
		})
	});		
})