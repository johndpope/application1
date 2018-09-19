window.shared_media_audios_index = ->
  $('a.tags_for_uploaded_audio').popover
    content: ->
      labels = $.map $(this).data('tags'), (e) ->
        "<span class='label label-primary label-tags'>#{e.name}</span>"
      labels.join(' ')
    title: 'Tags',
    html: true,
    placement: 'top',
    trigger: 'hover'

  $('#audio-search-btn').on 'click', ->
    $('#audio_search_form').submit()

  $("#audio-clear-btn").on 'click', ->
    $('input#q').val("")
    $('#search_conditions select').val('').select2('val','')
    $('#search_conditions input[type="text"], input[type="search"] ').val('')

  $('#limit, #client_id_eq, #file_content_type_cont').select2
    placeholder: "Choose ..."
    allowClear: true

  $('#tags_name_cont').tagsinput
    tagClass: "label label-primary"
