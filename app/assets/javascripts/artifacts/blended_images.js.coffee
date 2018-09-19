fancybox_settings = {
  helpers: {
    title : {
      type : 'float'
    }
  }
}
window.artifacts_blended_images_index = ->
  $('body').popover
    selector: 'a.tags-toggle',
    content: ->
      labels = $.map $(this).data('tags').split(','), (e) ->
        "<span class='label label-success label-tags'>#{e}</span>"
      labels.join(' ')
    title: 'Tags',
    html: true,
    placement: 'top',
    trigger: 'hover'

  $('.livepreview').livePreview({
    position: 'left'
  });

  $(".image-preview").fancybox(fancybox_settings);
