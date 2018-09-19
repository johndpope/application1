#= require fancybox
fancybox_settings = {
  helpers: {
    title : {
      type : 'float'
    }
  }
}
window.artifacts_images_index = ->
  $(".image-preview").fancybox(fancybox_settings)
  $('.artifacts_image input[type=checkbox]').iCheck
    checkboxClass: 'icheckbox_flat-green',
    # radioClass: 'iradio_flat-green',
    increaseArea: '20%'

  $('.artifacts_image input[type=checkbox]').on 'ifChecked', ->
    $(this).attr('checked', true)
    $('#import-dialog-toggle').show()

  $('.artifacts_image input[type=checkbox]').on 'ifUnchecked', ->
    $(this).attr('checked', false)
    $('#import-dialog-toggle').hide() if $('.artifacts_image input[type=checkbox]:checked').length == 0

  $('#select-toggle #all').on 'click', ->
    $('.artifacts_image input[type=checkbox]').each ->
      if !$(this)[0].hasAttribute('disabled')
        $(this).iCheck('check')

  $('#select-toggle #none').on 'click', ->
    $('.artifacts_image input[type=checkbox]').iCheck('uncheck')

  # $('#search').on 'change', -> $(this).submit()
  $('.search-btn').on 'click', ->
    $('#search').submit()

  data = [
    { id: 0, text: '<div style="letter-spacing: 15px"><i class="fa fa-star-o"></i><i class="fa fa-star-o"></i><i class="fa fa-star-o"></i><i class="fa fa-star-o"></i><i class="fa fa-star-o"></i></div>' },
    { id: 1, text: '<div style="letter-spacing: 15px"><i class="fa fa-star"></i><i class="fa fa-star-o"></i><i class="fa fa-star-o"></i><i class="fa fa-star-o"></i><i class="fa fa-star-o"></i></div>' }
    { id: 2, text: '<div style="letter-spacing: 15px"><i class="fa fa-star"></i><i class="fa fa-star"></i><i class="fa fa-star-o"></i><i class="fa fa-star-o"></i><i class="fa fa-star-o"></i></div>' }
    { id: 3, text: '<div style="letter-spacing: 15px"><i class="fa fa-star"></i><i class="fa fa-star"></i><i class="fa fa-star"></i><i class="fa fa-star-o"></i><i class="fa fa-star-o"></i></div>' }
    { id: 4, text: '<div style="letter-spacing: 15px"><i class="fa fa-star"></i><i class="fa fa-star"></i><i class="fa fa-star"></i><i class="fa fa-star"></i><i class="fa fa-star-o"></i></div>' }
    { id: 5, text: '<div style="letter-spacing: 15px"><i class="fa fa-star"></i><i class="fa fa-star"></i><i class="fa fa-star"></i><i class="fa fa-star"></i><i class="fa fa-star"></i></div>' }
  ];

  $('#rating').select2
    placeholder: "Choose rating..."
    allowClear: true
    data: data,
    escapeMarkup: (markup)->
      markup;

  $('#limit, #sort, #has_gravity_point, #broadcaster_property, #import_status, #is_local, #reusable, #ransack_dynamic_image_id_present, #ransack_type_cont, #ransack_type_eq, #extension, #client_id, #use_for_landing_pages, #by_resolution').select2
    placeholder: "Choose ..."
    width: '100%',
    minimumInputLength: 0,
    allowClear: true

  selected_country_id = window.sessionStorage.getItem('artifacts-images-import-country-id')
  selected_country_name = window.sessionStorage.getItem('artifacts-images-import-country-name')
  selected_region1_id = window.sessionStorage.getItem('artifacts-images-import-region1-id')
  selected_region1_name = window.sessionStorage.getItem('artifacts-images-import-region1-name')
  selected_region2_id = window.sessionStorage.getItem('artifacts-images-import-region2-id')
  selected_region2_name = window.sessionStorage.getItem('artifacts-images-import-region2-name')
  selected_city_id = window.sessionStorage.getItem('artifacts-images-import-city-id')
  selected_city_name = window.sessionStorage.getItem('artifacts-images-import-city-name')
  selected_tag_list = window.sessionStorage.getItem('artifacts-images-import-tag_list')

  if (selected_country_id == null || selected_country_id == 'undefined' || selected_country_id == '')
    selected_country_id = $('#country_default').data('id')
    selected_country_name = $('#country_default').data('name')
    window.sessionStorage.setItem('artifacts-images-import-country-id', selected_country_id)
    window.sessionStorage.setItem('artifacts-images-import-country-name', selected_country_name)

  $('#country').val(selected_country_id)
  $('#region1').val(selected_region1_id)
  $('#region2').val(selected_region2_id)
  $('#city').val(selected_city_id)
  $('#tag_list').val(selected_tag_list)

  $('#country').select2
    placeholder: 'Choose',
    width: '100%',
    minimumInputLength: 0,
    allowClear: true,
    ajax:
      url: '/geobase/countries.json',
      quietMillis: 300,
      data: (term, page) ->
        { name_or_code_cont: term, page: page, per_page: 10, sorts: 'name asc' }
      results: (data, page) ->
        {
          results: $.map(data.items, (e) -> { id: e.id, text: e.name }),
          more: (page * 10) < data.total
        }
    initSelection: (element, callback) ->
      data = {id: selected_country_id, text: selected_country_name}
      callback(data)

  $('#region1').select2
    placeholder: 'Choose',
    width: '100%',
    minimumInputLength: 0,
    allowClear: true,
    ajax:
      url: '/geobase/regions.json',
      quietMillis: 300,
      data: (term, page) ->
        {
          name_or_code_cont: term,
          level_eq: 1,
          country_id_eq: $('#country').val(),
          page: page,
          per_page: 10,
          sorts: 'name asc'
        }
      results: (data, page) ->
        {
          results: $.map(data.items, (e) -> { id: e.id, text: e.name }),
          more: (page * 10) < data.total
        }
    initSelection: (element, callback) ->
      data = {id: selected_region1_id, text: selected_region1_name}
      callback(data)

  $('#region2').select2
    placeholder: 'Choose',
    width: '100%',
    minimumInputLength: 0,
    allowClear: true,
    ajax:
      url: '/geobase/regions.json',
      quietMillis: 300,
      data: (term, page) ->
        {
          name_or_code_cont: term,
          level_eq: 2,
          country_id_eq: $('#country').val(),
          parent_id_eq: $('#region1').val(),
          page: page,
          per_page: 10,
          sorts: 'name asc'
        }
      results: (data, page) ->
        {
          results: $.map(data.items, (e) -> { id: e.id, text: e.name }),
          more: (page * 10) < data.total
        }
    initSelection: (element, callback) ->
      data = {id: selected_region2_id, text: selected_region2_name}
      callback(data)

  $('#city').select2
    placeholder: 'Choose',
    width: '100%',
    minimumInputLength: 0,
    allowClear: true,
    ajax:
      url: '/geobase/localities.json',
      quietMillis: 300,
      data: (term, page) ->
        {
          name_or_code_cont: term,
          country_id_eq: $('#country').val(),
          primary_region_id_eq: $('#region1').val(),
          page: page,
          per_page: 10,
          sorts: ['population desc', 'name asc']
        }
      results: (data, page) ->
        {
          results: $.map(data.items, (e) -> { id: e.id, text: e.name }),
          more: (page * 10) < data.total
        }
    initSelection: (element, callback) ->
      data = {id: selected_city_id, text: selected_city_name}
      callback(data)

  $('#country_name').val($('#country').select2("data").text)
  $('#country').on 'change', ->
    if (country_id = $(this).val())
      window.sessionStorage.setItem('artifacts-images-import-country-id', country_id)
      window.sessionStorage.setItem('artifacts-images-import-country-name', $('#country').select2('data').text)
      $('#country_name').val($('#country').select2("data").text)
    else
      window.sessionStorage.setItem('artifacts-images-import-country-id', '')
      window.sessionStorage.setItem('artifacts-images-import-country-name', '')
      window.sessionStorage.setItem('artifacts-images-import-region1-id', '')
      window.sessionStorage.setItem('artifacts-images-import-region1-name', '')
      window.sessionStorage.setItem('artifacts-images-import-region2-id', '')
      window.sessionStorage.setItem('artifacts-images-import-region2-name', '')
      window.sessionStorage.setItem('artifacts-images-import-city-id', '')
      window.sessionStorage.setItem('artifacts-images-import-city-name', '')
      window.sessionStorage.setItem('artifacts-images-import-tag_list', '')
      $('#region1').select2('val', '')
      $('#region2').select2('val', '')
      $('#city').select2('val', '')
      $('#tag_list').val('')
      $('#country_name').val('')
      $('#lat').val("")
      $('#lng').val("")


  $('#region1').on 'change', ->
    if (region1_id = $(this).val())
      window.sessionStorage.setItem('artifacts-images-import-region1-id', region1_id)
      window.sessionStorage.setItem('artifacts-images-import-region1-name', $('#region1').select2('data').text)
    else
      window.sessionStorage.setItem('artifacts-images-import-region1-id', '')
      window.sessionStorage.setItem('artifacts-images-import-region1-name', '')
      window.sessionStorage.setItem('artifacts-images-import-region2-id', '')
      window.sessionStorage.setItem('artifacts-images-import-region2-name', '')
      window.sessionStorage.setItem('artifacts-images-import-city-id', '')
      window.sessionStorage.setItem('artifacts-images-import-city-name', '')
      $('#region2').select2('val', '')
      $('#city').select2('val', '')
      $('#lat').val("")
      $('#lng').val("")

  $('#region2').on 'change', ->
    if (region2_id = $(this).val())
      window.sessionStorage.setItem('artifacts-images-import-region2-id', region2_id)
      window.sessionStorage.setItem('artifacts-images-import-region2-name', $('#region2').select2('data').text)
    else
      window.sessionStorage.setItem('artifacts-images-import-region2-id', '')
      window.sessionStorage.setItem('artifacts-images-import-region2-name', '')
      window.sessionStorage.setItem('artifacts-images-import-city-id', '')
      window.sessionStorage.setItem('artifacts-images-import-city-name', '')
      $('#city').select2('val', '')

  $('#city').on 'change', ->
    if (locality_id = $(this).val())
      $.get "/geobase/localities.json?id_eq=#{locality_id}", (data) ->
        locality = data.items[0]
        country = locality.country
        region1 = locality.primary_region
        region2 = locality.secondary_regions[0]
        window.sessionStorage.setItem('artifacts-images-import-country-id', country.id)
        window.sessionStorage.setItem('artifacts-images-import-country-name', country.name)
        if region1
          window.sessionStorage.setItem('artifacts-images-import-region1-id', region1.id)
          window.sessionStorage.setItem('artifacts-images-import-region1-name', region1.name)
          $('#region1').select2('data', { id: region1.id, text: region1.name })
        else
          window.sessionStorage.setItem('artifacts-images-import-region1-id', '')
          window.sessionStorage.setItem('artifacts-images-import-region1-name', '')
          $('#region1').select2('val', '')
        if region2
          window.sessionStorage.setItem('artifacts-images-import-region2-id', region2.id)
          window.sessionStorage.setItem('artifacts-images-import-region2-name', region2.name)
          $('#region2').select2('data', { id: region2.id, text: region2.name })
        else
          window.sessionStorage.setItem('artifacts-images-import-region2-id', '')
          window.sessionStorage.setItem('artifacts-images-import-region2-name', '')
          $('#region2').select2('val', '')

        window.sessionStorage.setItem('artifacts-images-import-city-id', locality.id)
        window.sessionStorage.setItem('artifacts-images-import-city-name', locality.name)
        $('#country').select2('data', { id: country.id, text: country.name })
    else
      window.sessionStorage.setItem('artifacts-images-import-city-id', '')
      window.sessionStorage.setItem('artifacts-images-import-city-name', '')
      window.sessionStorage.setItem('artifacts-images-import-region2-id', '')
      window.sessionStorage.setItem('artifacts-images-import-region2-name', '')
      $('#region2').select2('val', '')
      $('#lat').val("")
      $('#lng').val("")

  $('#tag_list').on 'change', ->
    window.sessionStorage.setItem('artifacts-images-import-tag_list', $(this).val())

  $('#import').on 'click', ->
    $(this).button('loading')
    api = $('input[name=api]').val()
    source_ids = $.map $('.box.artifacts_image input[type=checkbox]:checked'), (e) -> $(e).val()
    gravities = $.map $('.box.artifacts_image input[type=hidden]'), (e) ->
      if $(e).siblings('.check').find('input[type=checkbox]').is(':checked')
        return $(e).val()

    count = source_ids.length
    client_id = $('#client_id').val()
    country = $('#country').val()
    region1 = $('#region1').val()
    region2 = $('#region2').val()
    city = $('#city').val()
    tags = $('#tag_list').val()
    industry_id = $('#industry_id').val()
    reusable_radio = $('[name="reusable"]:checked')
    use_for_landing_pages_radio = $('[name="use_for_landing_pages"]:checked')
    label = ''

    data = {
      source_ids: source_ids,
      gravities: gravities,
      api: api,
      country: country,
      region1: region1,
      region2: region2,
      city: city,
      tag_list: tags,
      industry_id: industry_id,
      client_id: client_id
    }

    if(reusable_radio.length > 0)
      data['reusable'] = reusable_radio.val()
    if(use_for_landing_pages_radio.length > 0)
      data['use_for_landing_pages'] = use_for_landing_pages_radio.val()

    $.ajax
      url: "/artifacts/images/import",
      data: data,
      success: ->
        label = "<span class='label label-success'>IMPORTING ...</span>"
      error: ->
        label = "<span class='label label-danger'>ERROR</span>"
      complete: ->
        $.each source_ids, (i, source_id) ->
          if !$("#images_source_id_#{source_id}").disabled
            $("#images_source_id_#{source_id}").closest('.check').replaceWith(label)

        $('#import').button('reset')
        $('#import-dialog-toggle').hide()
        $('#import-dialog').modal('hide')

  $('#show_gravity_mask').on 'click', ->
    li = $(this).closest('li')
    if li.hasClass('active')
      li.removeClass('active')
    else
      li.addClass('active')
    $('i.dot').toggle()

  $('.dot').on 'click', ->
    parent = $(this).closest('[data-source-id]')
    $('.gravity-name', parent).html($(this).attr('data-gravity-name'))
    $('.dot', parent).removeClass('active')
    $(this).addClass('active')
    $('[name="images[gravity][]"]', parent).val($(this).attr('data-gravity'))

    if parent.attr('data-update-url') != ''
      $('.gravity-spin', parent).show()
      $.ajax
        url: parent.attr('data-update-url'),
        type: 'POST',
        data:
          gravity: $('[name="images[gravity][]"]', parent).val()
        success: ->
        error: ->
        complete: ->
          $('.gravity-spin', parent).hide()

  $('body').popover
    selector: 'a.tags-toggle',
    content: ->
      labels = $.map $(this).data('tags').split(','), (e) ->
        "<span class='label label-primary label-tags'>#{e}</span>"
      labels.join(' ')
    title: $(this).data('title'),
    html: true,
    placement: 'top',
    trigger: 'hover'
  $('#q').on 'keypress', (e) ->
    if e.which == 13
      $('#search').submit()

  $('#api-switch li').on 'click', ->
    api_text_before = $.trim($('#api-switch').find('li.active').first().text())
    $('#api-switch li').removeAttr('class')
    $(this).addClass('active')
    selected_api = $.trim($(this).text())
    api_text = selected_api
    console.log(api_text);
    document.getElementById('api-switch-btn').innerHTML = api_text + '&nbsp;&nbsp;&nbsp;<i class="fa fa-caret-down"></i>'
    if api_text == 'Local' || api_text == 'Dynamic'
      api_text = ''
    $('#api').val(api_text)
    if api_text == ''
      window.location.replace("/artifacts/images")
    else
      window.location.replace("/artifacts/images?utf8=✓&q=&api=" + api_text + "&limit=" + $('#limit').val())

  # Search suggestions autocomplete
  $('#q').autocomplete
    minLength: 3,
    delay: 500,
    source: (request, callback) ->
      $.getJSON "/artifacts/search_suggestions.json?phrase=#{request.term}", (response) ->
        callback(response)
    select: (event, ui) ->
      $('#q').val(ui.item.value)
      $('#search').submit()

  $('.advanced-toggle').on 'click', ->
    $('.advanced').toggle()
    $(this).find('.fa').toggleClass('fa-minus', 'fa-plus')
    key = 'artifacts.images.advanced'
    if window.sessionStorage.getItem(key)
      window.sessionStorage.removeItem(key)
    else
      window.sessionStorage.setItem(key, 'on')

  if window.sessionStorage.getItem('artifacts.images.advanced')
    $('.advanced').show()
    $('.advanced-toggle .fa').toggleClass('fa-minus', 'fa-plus')

  $('.reject-image').bind 'ajax:complete', ->
    $(this).closest('.artifacts_image').first().append('<div class="overlay"></div>')
    source_id_checkbox = $('#images_source_id_' + $(this).closest('.artifacts_image').first().parent().data("source-id"))
    source_id_checkbox.iCheck('uncheck')
    source_id_checkbox.iCheck('disable')
    $(this).closest('.artifacts_image').first().find('.box-tools .check').first().hide()
    $(this).closest('.artifacts_image').first().find('.box-tools').first().append('<span class="label label-danger">REJECTED</span>')
    $(this).attr('disabled', 'disabled')
    $(this).next().removeAttr('disabled')
  $('.unreject-image').bind 'ajax:complete', ->
    source_id_checkbox = $('#images_source_id_' + $(this).closest('.artifacts_image').first().parent().data("source-id"))
    source_id_checkbox.iCheck('enable')
    source_id_checkbox.iCheck('check')
    source_id_checkbox.parent().effect('highlight', { color: '#EFFF00' }, 500)
    $(this).closest('.artifacts_image').first().find('.overlay').first().remove()
    $(this).closest('.artifacts_image').first().find('.box-tools .check').first().show()
    $(this).closest('.artifacts_image').first().find('.box-tools').first().find('.label-danger').first().remove()
    $(this).attr('disabled', 'disabled')
    $(this).prev().removeAttr('disabled')

  $('#ransack_industry_id_eq').select2
    dropdownCssClass: 'bigdrop'
    placeholder: 'Select industry by NAICS industry code or by typing industry name'
    allowClear: true
    ajax:
      url: '/industries/tools/json_list'
      dataType: 'json'
      data: (term, page) ->
        { id: $(this).val(), q: term }
      results: (data, page) ->
        { results: data }
    initSelection: (item, callback) ->
      id = item.val()
      if id != ''
        $.ajax('/industries/tools/json_list',
          data: id: id
          dataType: 'json').done (data) ->
            callback data[0]
    formatResult: (item) ->
      item.text
    formatSelection: (item) ->
      item.text
    escapeMarkup: (m) ->
      m

    $('#industry_id').select2
    dropdownCssClass: 'bigdrop'
    placeholder: 'Select industry by NAICS industry code or by typing industry name'
    allowClear: true
    ajax:
      url: '/industries/tools/json_list'
      dataType: 'json'
      data: (term, page) ->
        { id: $(this).val(), q: term }
      results: (data, page) ->
        { results: data }
    initSelection: (item, callback) ->
      id = item.val()
      if id != ''
        $.ajax('/industries/tools/json_list',
          data: id: id
          dataType: 'json').done (data) ->
            callback data[0]
    formatResult: (item) ->
      item.text
    formatSelection: (item) ->
      item.text
    escapeMarkup: (m) ->
      m
  .select2('val', window.sessionStorage.getItem('artifacts-images-import-industry_id'))
  $('#ransack_industry_id_eq, #industry_id').on "click", ->
    $(this).select2("open")

  $('#industry_id').on 'change', ->
    window.sessionStorage.setItem('artifacts-images-import-industry_id', $(this).val())

  $('#client_id').on 'change', ->
    window.sessionStorage.setItem('artifacts-images-import-client-id', $(this).val())

  $('#client_id').val(window.sessionStorage.getItem('artifacts-images-import-client-id'))

  $('#ransack_country_cont').select2
    placeholder: 'Choose country',
    width: '100%',
    minimumInputLength: 0,
    allowClear: true,
    ajax:
      url: '/geobase/countries.json',
      quietMillis: 300,
      data: (term, page) ->
        {
          name_or_code_cont: term,
          page: page,
          per_page: 10,
          sorts: 'name asc'
        }
      results: (data, page) ->
        {
          results: $.map(data.items, (e) -> { id: e.name, text: e.name }),
          more: (page * 10) < data.total
        }
    initSelection: (element, callback) ->
      data = {id: element.val(), text: element.val()}
      callback(data)
  .on "change", (e) ->
    if (e.val != "")
      $.get "/geobase/countries.json?name_cont=#{$('#ransack_country_cont').val()}", (data) ->
        $('#ransack_country_cont').data("id", data.items[0].id)
    else
      $('#ransack_country_cont').data("id","")
      $('#ransack_country_cont').select2('val','')
      $('#ransack_region1_cont').data("id", "")
      $('#ransack_region1_cont').select2('val','')
      $('#ransack_region2_cont').data("id", "")
      $('#ransack_region2_cont').select2('val','')
      $('#ransack_city_cont').data("id", "")
      $('#ransack_city_cont').select2('val','')

  $('#ransack_region1_cont').select2
    placeholder: 'Choose state',
    width: '100%',
    minimumInputLength: 0,
    allowClear: true,
    ajax:
      url: '/geobase/regions.json',
      quietMillis: 300,
      data: (term, page) ->
        {
          name_or_code_cont: term,
          level_eq: 1,
          country_id_eq: $('#ransack_country_cont').data("id"),
          page: page,
          per_page: 10,
          sorts: 'name asc'
        }
      results: (data, page) ->
        {
          results: $.map(data.items, (e) -> { id: e.name, text: e.name, region1_id: e.id }),
          more: (page * 10) < data.total
        }
    initSelection: (element, callback) ->
      data = {id: element.val(), text: element.val()}
      callback(data)
  .on "change", (e) ->
    if (e.val != "")
      $.get "/geobase/regions.json?name_cont=#{$('#ransack_region1_cont').val()}", (data) ->
        $('#ransack_region1_cont').data("id", data.items[0].id)
    else
      $('#ransack_region1_cont').data("id", "")
      $('#ransack_region1_cont').select2('val','')
      $('#ransack_region2_cont').data("id", "")
      $('#ransack_region2_cont').select2('val','')
      $('#ransack_city_cont').data("id", "")
      $('#ransack_city_cont').select2('val','')

  $('#ransack_region2_cont').select2
    placeholder: 'Choose county',
    width: '100%',
    minimumInputLength: 0,
    allowClear: true,
    ajax:
      url: '/geobase/regions.json',
      quietMillis: 300,
      data: (term, page) ->
        {
          name_or_code_cont: term,
          level_eq: 2,
          country_id_eq: $('#ransack_country_cont').data("id"),
          parent_name_eq: $('#ransack_region1_cont').val(),
          page: page,
          per_page: 10,
          sorts: 'name asc'
        }
      results: (data, page) ->
        {
          results: $.map(data.items, (e) -> { id: e.name, text: e.name }),
          more: (page * 10) < data.total
        }
    initSelection: (element, callback) ->
      data = {id: element.val(), text: element.val()}
      callback(data)
  .on "change", (e) ->
    if (e.val != "")
      $.get "/geobase/regions.json?country_id_eq=#{$('#ransack_country_cont').data('id')}&level_eq=2&parent_id_eq=#{$('#ransack_region1_cont').data('id')}&name_cont=#{e.val}", (data) ->
        $('#ransack_region2_cont').data("id", data.items[0].id)
    else
      $('#ransack_region2_cont').data("id", "")
      $('#ransack_region2_cont').select2('val','')
      $('#ransack_city_cont').data("id", "")
      $('#ransack_city_cont').select2('val','')

  $('#ransack_city_cont').select2
    placeholder: 'Choose city',
    width: '100%',
    minimumInputLength: 0,
    allowClear: true,
    ajax:
      url: '/geobase/localities.json',
      quietMillis: 300,
      data: (term, page) ->
        {
          name_or_code_cont: term,
          country_id_eq: $('#ransack_country_cont').data("id"),
          primary_region_name_eq: $('#ransack_region1_cont').val(),
          page: page,
          per_page: 10,
          sorts: ['population desc', 'name asc']
        }
      results: (data, page) ->
        {
          results: $.map(data.items, (e) -> { id: e.name, text: e.name }),
          more: (page * 10) < data.total
        }
    initSelection: (element, callback) ->
      data = {id: element.val(), text: element.val()}
      callback(data)
  .on "change", (e) ->
    if (e.val != "")
      $.get "/geobase/localities.json?name_eq=#{$('#ransack_city_cont').val()}", (data) ->
        $('#ransack_city_cont').data("id", data.items[0].id)
    else
      $('#ransack_city_cont').data("id", "")
      $('#ransack_city_cont').select2('val','')

  $('.img_rating').on 'click', (e)->
    data_index = $(this).index();
    image_id = $(this).data('id');
    $(this).closest('.rating_block').find('i').removeClass('fa-star').addClass('fa-star-o');
    for i in [0..data_index]
      $(this).closest('.rating_block').find('i').eq(i).removeClass('fa-star-o').addClass('fa-star');

    rating = $(this).closest('.rating_block').find('.fa-star').length;
    $.ajax "/artifacts/images/#{image_id}/set_rating/#{rating}",
      type: 'GET'
      data: {image_id: image_id, rating: rating}

  $('.clear_categories_filter').on 'click', ->
    $.each $(".image_categories"), (k,v)->
      $(v).prop('checked', false);
