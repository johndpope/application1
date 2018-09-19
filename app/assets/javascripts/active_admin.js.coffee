#= require active_admin/base
#= require google_accounts
#= require youtube_videos
#= require video_scripts
#= require jquery_clipboard
#= require jquery_jstorage
#= require rich
#= require jquery.ui.core
#= require lib/pusher.min

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
