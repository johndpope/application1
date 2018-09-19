#= require fancybox
  $("#hidden_link").trigger('click')

  $('.carousel').carousel({
    interval: 5000
  })

  $('#hero-video').on 'click', ->
    if (this.paused)
      this.play();
    else
      this.pause();
