#= require 'jquery_nested_form'
window.clients_subject_videos = ->
  $('body').popover
    selector: 'a.source-video-tags',
    content: ->
      labels = $.map $(this).data('tags').toString().split(','), (e) ->
        "<span class='label label-primary label-tags'>#{e}</span>"
      labels.join(' ')
    html: true,
    placement: 'top',
    trigger: 'hover'
  stripped_url = document.location.toString().split("#")
  if (stripped_url.length > 1)
    search_element_id = "#" + stripped_url[1]
    $('html, body').animate({scrollTop: $(search_element_id).offset().top - 50}, 1000)
    $(search_element_id  + " td").css("background-color", "yellow")
    $(search_element_id).find('.edit-btn').trigger('click')

  $("body").on "nested:fieldAdded", '#dynamic_texts_accordion', (event) ->
    panel = event.field.closest('.panel-collapse')
    $('input[type=hidden][data-type=project_type]',event.field).val(panel.data('project-type'))
    $('input[type=hidden][data-type=text_type]',event.field).val(panel.data('text-type'))
    $('.form-control',event.field).attr('maxlength', panel.data('character-limit')).attr('placeholder','Enter text (character limit: ' + panel.data('character-limit') + ')')

  $('body').on 'nested:fieldAdded nested:fieldRemoved', '#dynamic_texts_accordion', (event) ->    
    panel = event.field.closest('.panel')
    text_strings_count = $('.dynamic-text-box:visible',panel).length
    text_strings_counter = $('.panel-title span.label', panel)
    text_counter_class_prefix = if text_strings_count == 0 then 'danger' else 'primary'
    text_strings_counter.removeClass('label-primary').removeClass('label-danger').addClass("label-#{text_counter_class_prefix}")
    text_strings_counter.html(text_strings_count)

  $('body').on 'keyup','#dynamic_texts_accordion .dynamic-text-box :text', ->
    length = $(this).val().length
    $('strong.character-limit',$(this).closest('.dynamic-text-box')).html(length)
