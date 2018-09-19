window.admin_sandbox_videos_index = ->
  $('[data-toggle="popover"]').popover()
  $('#q_video_set_id_eq').select2
    placeholder: 'Choose',
    width: '100%',
    minimumInputLength: 0,
    allowClear: true,
    ajax:
      url: '/admin/sandbox/video_sets.json',
      quietMillis: 300,
      data: (term, page) ->
        {
          "q[client_id_eq]": $('#q_video_set_client_id_eq').val(),
          page: page,
          per_page: 10
        }
      results: (data, page) ->
        {
          results: $.map(data.items, (e) -> { id: e.id, text: e.title }),
          more: (page * 10) < data.total
        }
  current_video_set_json = JSON.parse($('#current_video_set_json').val())
  $('#q_video_set_id_eq').select2('data', {id: current_video_set_json.id, text: current_video_set_json.title}) if current_video_set_json? && current_video_set_json?.title

  $(window).on 'show.bs.modal', ()->
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
        data = {id: element.val(), text: element.data('name')}
        callback(data)

    $('#region1').select2
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

    $('#region2').select2
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

    $('#city').select2
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


    $('#country').on 'change', (e)->
      $('#region1, #region2, #city').select2('val',"");
      if $('#country').val() != ''
        $('#sandbox_video_location_type').val('Geobase::Country');
        $('#sandbox_video_location_id').val($('#country').val());
      else
        $('#sandbox_video_location_type, #sandbox_video_location_id').val('');

    $('#region1').on 'change', (e)->
      $('#region2, #city').select2('val',"")
      if $('#region1').val() != ''
        $('#sandbox_video_location_type').val('Geobase::Region');
        $('#sandbox_video_location_id').val($('#region1').val());
      else if $('#country').val() != ''
        $('#sandbox_video_location_type').val('Geobase::Country');
        $('#sandbox_video_location_id').val($('#country').val());
      else
        $('#sandbox_video_location_type, #sandbox_video_location_id').val('');

    $('#region2').on 'change', (e)->
      $('#city').select2('val',"")
      if $('#region2').val() != ''
        $('#sandbox_video_location_type').val('Geobase::Region');
        $('#sandbox_video_location_id').val($('#region2').val());
      else if $('#region1').val() != ''
        $('#sandbox_video_location_type').val('Geobase::Region');
        $('#sandbox_video_location_id').val($('#region1').val());
      else if $('#country').val() != ''
        $('#sandbox_video_location_type').val('Geobase::Country');
        $('#sandbox_video_location_id').val($('#country').val());
      else
        $('#sandbox_video_location_type, #sandbox_video_location_id').val('');

    $('#city').on 'change', ->
      if (locality_id = $(this).val())
        $.get "/geobase/localities.json?id_eq=#{locality_id}", (data) ->
          locality = data.items[0]
          country = locality.country
          region1 = locality.primary_region
          region2 = locality.secondary_regions[0]
          $('#country').select2('data', { id: country.id, text: country.name })
          $('#region1').select2('data', { id: region1.id, text: region1.name })
          $('#region2').select2('data', { id: region2.id, text: region2.name })

      if $('#city').val() != ''
        $('#sandbox_video_location_type').val('Geobase::Locality');
        $('#sandbox_video_location_id').val($('#city').val());
      else
        $('#sandbox_video_location_type').val('Geobase::Region');
        $('#sandbox_video_location_id').val($('#region2').val());

    if(location_json = $('#location_json').val())
      json = JSON.parse(location_json)
      $('#country').select2('data', { id: json.country.id, text: json.country.name }) if json.country.name? && json.country.id?
      $('#region1').select2('data', { id: json.region1.id, text: json.region1.name }) if json.region1.name && json.region1.id?
      $('#region2').select2('data', { id: json.region2.id, text: json.region2.name }) if json.region2.name && json.region2.id?
      $('#city').select2('data', { id: json.locality.id, text: json.locality.name }) if json.locality.name && json.locality.id?
