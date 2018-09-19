window.shared_media_videos_index = ->
  $('a.tags_for_uploaded_video').popover
    content: ->
      labels = $.map $(this).data('tags'), (e) ->
        "<span class='label label-primary label-tags'>#{e.name}</span>"
      labels.join(' ')
    title: 'Tags',
    html: true,
    placement: 'top',
    trigger: 'hover'

  $(".preview-video").each ->
    src = $(this).attr('href');
    content = '<video src="' + src + '" autoplay="true" type="video/mp4" controls="true" style="height: 540px; width: 960px" onloadstart="this.volume=0.35"></video>';
    $(this).fancybox({content: content, minHeight: 540, minWidth: 960});

  $('#video-search-btn').on 'click', ->
    $('#video_search_form').submit()

  $('#tags_name_cont').tagsinput({
    tagClass: "label label-primary",
    placeholder: "Enter tags..."
  });

  $('#video-clear-btn').on 'click', ->
    $('input#q').val("")
    $('#search_conditions select').val('').select2('val','')
    $('#search_conditions input[type="text"], input[type="search"] ').val('')
    $('#country, #region1, #region2, #city').select2('val','')

  $('#limit, #client_id_eq').select2
    placeholder: "Choose ..."
    allowClear: true

  $('#country').select2
    placeholder: 'Choose country',
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
  .on "change", (e) ->
    if (e && e.removed)
      $('#region1').select2("val","")
      $('#region2').select2("val","")
      $('#city').select2("val","")

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
          country_id_eq:  $('#country').val(),
          page: page,
          per_page: 10,
          sorts: 'name asc'
        }
      results: (data, page) ->
        {
          results: $.map(data.items, (e) -> { id: e.id, text: e.name }),
          more: (page * 10) < data.total
        }
  .on "change", (e) ->
    if (e && e.removed)
      $('#region2').select2("val","")
      $('#city').select2("val","")

  $('#region2').select2
    placeholder: 'Choose locality',
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
  .on "change", (e) ->
    if (e && e.removed)
      $('#city').select2("val","")

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

  $('#city').on 'change', ->
    if (locality_id = $(this).val())
      $.get "/geobase/localities.json?id_eq=#{locality_id}", (data, status) ->
        locality = data.items[0]
        country = locality.country
        region1 = locality.primary_region
        region2 = locality.secondary_regions[0]
        $('#country').select2('data', { id: country.id, text: country.name })
        $('#region1').select2('data', { id: region1.id, text: region1.name })
        $('#region2').select2('data', { id: region2.id, text: region2.name })

  urlParam = (name) ->
    results = new RegExp('[\?&]' + name + '=([^&#]*)').exec(window.location.href);
    results[1] || 0;

  if (urlParam('country') != 0)
    $.get "/geobase/countries.json?id_eq=#{urlParam('country')}", (data) ->
      country_name = data['items'][0].name;
      $('#country').select2('data', {id: urlParam('country'), text: country_name});

  if (urlParam('region1') != 0)
    $.get "/geobase/regions.json?id_eq=#{urlParam('region1')}", (data) ->
      region1_name = data['items'][0].name
      $('#region1').select2('data', {id: urlParam('region1'), text: region1_name});

  if (urlParam('region2') != 0)
    $.get "/geobase/regions.json?id_eq=#{urlParam('region2')}", (data) ->
      region2_name = data['items'][0].name
      $('#region2').select2('data', {id: urlParam('region2'), text: region2_name});

  if (urlParam('city') != 0)
    $.get "/geobase/localities.json?id_eq=#{urlParam('city')}", (data) ->
      city_name = data['items'][0].name
      $('#city').select2('data', {id: urlParam('city'), text: city_name});
