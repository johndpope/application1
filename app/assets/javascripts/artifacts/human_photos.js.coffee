# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
fancybox_settings = {
  helpers: {
    title : {
      type : 'float'
    }
  }
}

window.artifacts_human_photos_index = ->
	$(".human-photo-preview").fancybox(fancybox_settings);
