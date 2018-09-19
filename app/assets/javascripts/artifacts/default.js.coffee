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

  $('#scroll-up').on 'click', ->
    $('html, body').animate({ scrollTop: 0 }, 800)
  $('#scroll-down').on 'click', ->
    $('body, html').animate({ scrollTop: $(document).height() }, 800)

  notifyMe = (title, options) ->
    if ('Notification' in window)
      alert options['body']
    else
      switch Notification.permission.toLowerCase()
        when "granted"
          notification = new Notification(title, options)
        when "denied"
          alert(options["body"])
        when "default"
          Notification.requestPermission()
          alert(options["body"])

  spawnNotification = (theBody, theIcon, theTitle) ->
    options =
      body: theBody
      icon: theIcon
    n = new Notification(theTitle, options)

  Notification.requestPermission()

  pusher = new Pusher('0e12cf705e3afee69722',
    cluster: 'eu'
    encrypted: true)
  channel = pusher.subscribe('default_channel')
  channel.bind 'deploy_event', (data) ->
    options =
      body: data.message
      icon: '/favicon.ico'
      tag: 'deploy'
    notifyMe data.title, options
  channel.bind 'default_event', (data) ->
    options =
      body: data.message
      icon: '/favicon.ico'
      tag: 'default'
    notifyMe data.title, options
