times = 0
$('.livepreview').livePreview({position: 'right'});
fancybox_settings = {
  prevEffect: 'none',
  nextEffect: 'none',
  closeBtn: false,
  helpers: {
    title: { type: 'inside' },
    buttons: {}
  }
}

$('select').select2
  placeholder: 'Choose ...',
  minimumInputLength: 0,
  allowClear: true

window.public_clients_youtube_videos = ->
  $(".youtube-video-thumbnail").fancybox(fancybox_settings);
  $(".youtube-video-screenshot").fancybox(fancybox_settings);
  $('.youtube-video-description').popover()
  $('body').popover
    selector: 'a.youtube-video-tags',
    content: ->
      labels = $.map $(this).data('tags').toString().split(','), (e) ->
        "<span class='label label-info'>#{e}</span>"
      labels.join(' ')
    html: true,
    placement: 'top',
    trigger: 'hover'

window.public_clients_youtube_channels = ->
  $('.youtube-channel-icon').fancybox(fancybox_settings);
  $('.youtube-channel-art').fancybox(fancybox_settings);
  $('.youtube-channel-screenshot').fancybox(fancybox_settings);

ready = ->
  window.default()
  page = $('body').data('page')
  window[page]() if ('function' == typeof(window[page]))

$(document).ready(ready)
$(document).on('page:load', ready)

window.default = ->
  $('.sidebar-toggle').on 'click', ->
    state = if $('body').hasClass('sidebar-collapse') then 'collapse' else 'open'
    window.localStorage.setItem('sidebar', state)
  if (state = window.localStorage.getItem('sidebar'))
    $('body').removeClass('sidebar-open').removeClass('sidebar-collapse').addClass("sidebar-#{state}")

  $('#toolbar-toggle').on 'click', ->
    if !$(this).hasClass('open')
      $(this).animate({ 'right': '250px' })
      $('#toolbar').animate({ 'right': '0' })
      $(this).addClass('open')
    else
      $(this).animate({ 'right': '0' })
      $('#toolbar').animate({ 'right': '-250px' })
      $(this).removeClass('open')

  $('.search-btn').on 'click', ->
    $('#search').submit()

  $('#scroll-up').on 'click', ->
    $('html, body').animate({ scrollTop: 0 }, 500)

  $(window).on 'scroll', ->
    if $(this).scrollTop() > 0 then $('#scroll-up').show() else $('#scroll-up').hide()
