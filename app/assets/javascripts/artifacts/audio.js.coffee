#= require fancybox2
#= require jquery-live-preview

window.artifacts_audios_index = ->
  $('.livepreview.left-livepreview').livePreview({
    position: 'left'
  });

  $('.livepreview').livePreview();

  $('#filter, #license, #type, #order, #boost, #audioformat, #limit, #ransack_client_id_eq, #ransack_file_content_type_cont, #ransack_type_cont, #ransack_genre_eq, #ransack_author_id_eq, #ransack_attribution_required_eq, #ransack_is_approved_eq, #ransack_mood_eq, #ransack_instrument_eq, #ransack_sound_type_eq, #ransack_artifacts_artist_id_eq, #ransack_audio_category_eq').select2
    placeholder: "Choose ..."
    allowClear: true

  $("#audio-search-btn").on 'click', ->
    $('#audio_search_form').submit()
  $('#api-switch li').on 'click', ->
    api_text_before = $.trim($('#api-switch').find('li.active').first().text())
    $('#api-switch li').removeAttr('class')
    $(this).addClass('active')
    selected_api = $.trim($(this).text())
    api_text = selected_api
    document.getElementById('api-switch-btn').innerHTML = api_text + '&nbsp;&nbsp;&nbsp;<i class="fa fa-caret-down"></i>'
    if api_text == 'Local'
      api_text = ''
    $('#api').val(api_text)
    if window.location.href.indexOf(api_text) <= -1
      window.location.replace("/artifacts/audios?utf8=✓&q=&api=" + api_text)

  $("#audio-clear-btn").on 'click', ->
    $('#q').val('')
    $('#search_conditions select').val('').select2('val','')
    $("#search_conditions input[type='search']").val('')
    $("#search_conditions input[type='text']").val('')

  $('body').popover
    selector: 'a.tags_for_audio',
    content: ->
      labels = $.map $(this).data('tags'), (e) ->
        "<span class='label label-success label-tags'>#{e.name}</span>"
      labels.join(' ')
    title: 'Tags',
    html: true,
    placement: 'top',
    trigger: 'hover'

  $('a.genres_for_audio').popover
    content: ->
      labels = $.map $(this).data('genres'), (e) ->
        "<span class='label label-success label-tags'>#{e.name}</span>"
      labels.join(' ')
    title: "Genres",
    html: true,
    placement: 'top',
    trigger: 'hover'

  $('#ransack_tags_name_cont').tagsinput
    tagClass: "label label-success"

  items = {}
  $(".is_approved_check_all").on "click", ->
    $('.is_approved_check').prop('checked', $(this).prop('checked'));
    $.each $(".is_approved_check"), (k,v)->
      items[$(v).data('id')]=$(v).prop('checked');
      console.log("");
    $.ajax
      url: "/artifacts/audios/group_update",
      data: {items: items}

  $(".is_approved_check").on "click", ->
    items[$(this).data('id')]=$(this).prop('checked');
    $.ajax
      url: "/artifacts/audios/group_update",
      data: {items: items}

  fancyPopup = ->
    el = ''
    audioTitle = ''
    posterPath = ''
    replacement = ''
    audioTag = ''
    fancyBoxId = ''
    posterPath = ''
    videoTitle = ''
    # Loop over each video tag.
    $('audio').each ->
      # Reset the variables to empty.
      el = ''
      audioTitle = ''
      posterPath = ''
      replacement = ''
      audioTag = ''
      fancyBoxId = ''
      posterPath = ''
      videoTitle = ''
      # Get a reference to the current object.
      el = $(this)
      # Set some values we'll use shortly.
      audioTagId = $(this).attr('id')
      audioTitle = $(this).parent().data('code')
      fancyBoxId = audioTagId + '_fancyBox'
      audioTag = el.parent().html()
      # This gets the current video tag and stores it.
      posterPath = el.attr('poster')
      # Concatenate the linked image that will take the place of the <video> tag.
      replacement = '<a title=\'' + audioTitle + '\' class=\'btn btn-xs btn-primary audio-fancybox\' id=\'' + fancyBoxId + '\' href=\'javascript:;\'><i class=\'fa fa-play\'></i></a>'
      # Replace the parent of the current element with the linked image HTML.
      el.parent().replaceWith replacement

      $('[id=' + fancyBoxId + ']').fancybox
        'content': audioTag
        'autoDimensions': true
        'padding': 5
        'showCloseButton': true
        'enableEscapeButton': true
        'width': 500
        'height': 45
        'titlePosition': 'outside'
        'beforeShow': ->
          this.element.title = audioTitle
          $('audio').attr 'autoplay', 'autoplay'
          $('audio').show()
        beforeClose: ->
          $('.audio-fancybox i.fa').removeClass('fa-pause').addClass 'fa-play'

  fancyPopup();
