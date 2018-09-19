window.artifacts_image_blender_index = ->
  $('#image_blender_type').select2({
    placeholder: "Choose type",
    allowClear: true
    })

  $('#image_blender_type').on 'change', ->
    url = $(this).data('url')
    type_val = $(this).val()

    $('#templates_settings').html('');
    $("#templates_by_type").hide();
    $("#blended_image_wrapper").hide();

    if type_val
      $("#templates_by_type").show();

      $.ajax '/artifacts/image_blender/templates_by_type.js',
        type: 'GET'
        data: {'type': type_val}
        error: (jqXHR, textStatus, errorThrown) ->
          alert "Error: #{textStatus}"
        success: (data, textStatus, jqXHR) ->
          $('#image_blender_image_template_id').on 'change', ->
            url = $(this).data('url')
            image_template_val = $(this).val()
            if image_template_val
              $.ajax "#{url}",
                type: 'GET',
                data: {'image_template_id': image_template_val}
                error: (jqXHR, t, err) ->
                success: (data, txt, jqXHR) ->
            else
              $('#templates_settings').html('')
    else
      $('#templates_settings').html('');
      $("#templates_by_type").hide();
      $("#blended_image_wrapper").hide();

  $('body').on 'click', '.button_blend', ->
    $('#form_blend').attr('action','/artifacts/image_blender/blend');
    $('#form_blend').submit();

  $('body').on 'click', '.button_import', ->
    $('#form_blend').attr('action','/artifacts/image_blender/import_image');
    $('#form_blend').submit();

  # select2 for llocalities------------------------------------------------------------------------------------
  $('#image_blender_region1').select2
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
          country_id_eq: 1,
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

  $('#image_blender_region2').select2
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
          country_id_eq: 1,
          parent_id_eq: $('#image_blender_region1').val(),
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

  $('#image_blender_city').select2
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
          country_id_eq: 1,
          primary_region_id_eq: $('#image_blender_region1').val(),
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

  $('body').on 'click', '.button_save', ->
    country = "United States of America";
    region1 = $("#image_blender_region1").val();
    region2 = $("#image_blender_region2").val();
    city = $("#image_blender_city").val();
    tags = $("#image_blender_tags").val();
    client_id = $("#image_blender_client_id").val();
    title = $("#image_blender_title").val();

    data = {
      country: country,
      region1: region1,
      region2: region2,
      city: city,
      tag_list: tags,
      client_id: client_id,
      title: title
    }

    $.ajax '/artifacts/image_blender/save_image',
      type: 'GET'
      data: data
      error: (jqXHR, textStatus, errorThrown) ->
        $('.button_save').closest('.panel').first().find('.panel-heading').append('<h3><span class="label label-danger">error saving</span></h3>').find("span").delay(3000).fadeOut(1000)
      success: (data, textStatus, jqXHR) ->
        $('.button_save').closest('.panel').first().find('.panel-heading').append('<h3><span class="label label-success">saved</span></h3>').find("span").delay(3000).fadeOut(1000)

  $('body').popover
    selector: 'a.tags-toggle',
    content: ->
      labels = $.map $(this).data('tags').split(','), (e) ->
        "<span class='label label-success label-tags'>#{e}</span>"
      labels.join(' ')
    title: $(this).data('title'),
    html: true,
    placement: 'top',
    trigger: 'hover'

  $('body').on 'change', '#is_special_eq', ->
    search_criteria_box = $('#search_criteria')
    if this.value
      search_criteria_box.removeAttr('name')
      search_criteria_box.attr('disabled', 'disabled')
    else
      search_criteria_box.removeAttr('disabled')
      search_criteria_box.attr('name', search_criteria_box.data('name'))
