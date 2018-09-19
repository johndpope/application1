#= require fancybox
fancybox_settings = {
  helpers: {
    title : {
      type : 'float'
    }
  }
}

window.shared_media_images_local_import =->
  selected_country_id = $('#country_default').data('id')
  selected_country_name = $('#country_default').data('name')

  $('[data-toggle="tooltip"]').tooltip('show');

  $('select').select2
    placeholder: 'Choose ...',
    width: '100%',
    minimumInputLength: 0,
    allowClear: true

  $('#image_content_type, #video_content_type, #audio_content_type').select2
    placeholder: 'Choose...',
    width: '80%',
    minimumInputLength: 0,
    allowClear: true

  $("#client_id").select2
    placeholder: 'Choose client',
    width: '100%',
    minimumInputLength: 0,
    allowClear: true
  .on "change", (e) ->
    if (e && e.removed)
      $("#products").select2("val","")
      $("#tags").tagsinput('removeAll')

  $("#products").select2
    placeholder: 'Choose product',
    width: '100%',
    minimumInputLength: 0,
    allowClear: true
  .on "change", (e) ->
    if (e && e.removed)
      $("#tags").tagsinput('removeAll')

  $('#country').val(selected_country_id)
  $('#video_country').val(selected_country_id)

  $('#country, #video_country').select2
    placeholder: 'Choose country',
    width: '80%',
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
  .on "change", (e) ->
    if $(this).select2("data") != null
      dt_name = $(this).select2("data").text;
      $(this).attr('data-name', dt_name);
      $(this).attr('data-id',e.val);
    if (e && e.removed)
      $(this).closest('.location').find('#region1, #region2, #city').select2('val','');

  $('#region1, #video_region1').select2
    placeholder: 'Choose state',
    width: '80%',
    minimumInputLength: 0,
    allowClear: true,
    ajax:
      url: '/geobase/regions.json',
      quietMillis: 300,
      data: (term, page) ->
        {
          name_or_code_cont: term,
          level_eq: 1,
          country_id_eq: $(this).closest('.location').find("[type=hidden].country").select2('val'),
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
    if $(this).select2("data") != null
      dt_name = $(this).select2("data").text;
      $(this).attr('data-name', dt_name);
      $(this).attr('data-id',e.val);
    if (e && e.removed)
      $(this).closest('.location').find('#region2, #city').select2('val', "");


  $('#region2, #video_region2').select2
    placeholder: 'Choose locality',
    width: '80%',
    minimumInputLength: 0,
    allowClear: true,
    ajax:
      url: '/geobase/regions.json',
      quietMillis: 300,
      data: (term, page) ->
        {
          name_or_code_cont: term,
          level_eq: 2,
          country_id_eq: $(this).closest('.location').find("[type=hidden].country").select2('val'),
          parent_id_eq: $(this).closest('.location').find("[type=hidden].region1").select2('val'),
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
    if $(this).select2("data") != null
      dt_name = $(this).select2("data").text;
      $(this).attr('data-name', dt_name);
      $(this).attr('data-id',e.val);
    if (e && e.removed)
      $(this).closest('.location').find("[type=hidden].city").select2('val', "");

  $('#city, #video_city').select2
    placeholder: 'Choose city',
    width: '80%',
    minimumInputLength: 0,
    allowClear: true,
    ajax:
      url: '/geobase/localities.json',
      quietMillis: 300,
      data: (term, page) ->
        {
          name_or_code_cont: term,
          country_id_eq: $(this).closest('.location').find("[type=hidden].country").select2('val'),
          primary_region_id_eq: $(this).closest('.location').find("[type=hidden].region1").select2('val'),
          page: page,
          per_page: 10,
          sorts: ['population desc', 'name asc']
        }
      results: (data, page) ->
        {
          results: $.map(data.items, (e) -> { id: e.id, text: e.name }),
          more: (page * 10) < data.total
        }
  .on 'change', (e) ->
    if $(this).select2("data") != null
      dt_name = $(this).select2("data").text;
      $(this).attr('data-name', dt_name);
      $(this).attr('data-id',e.val);

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

  $('#video_city').on 'change', ->
    if (locality_id = $(this).val())
      $.get "/geobase/localities.json?id_eq=#{locality_id}", (data, status) ->
        locality = data.items[0]
        country = locality.country
        region1 = locality.primary_region
        region2 = locality.secondary_regions[0]
        $('#video_country').select2('data', { id: country.id, text: country.name })
        $('#video_region1').select2('data', { id: region1.id, text: region1.name })
        $('#video_region2').select2('data', { id: region2.id, text: region2.name })

  $('#tags').tagsinput({tagClass: "label label-primary"});

  $('#fileupload').fileupload
    dataType: 'json',
    autoUpload: false,
    acceptFileTypes: /(\.|\/)(mp3|mp4|jpg|jpeg|png)$/i,
    maxFileSize: 40000000
  .on 'fileuploadchange', (e, data) ->
    $('.agreement, button.cancel_all, #local_import').removeClass('hidden');
    $('[data-tooltip="tooltip"]').tooltip('show');
  .on 'fileuploaddone', (e, data) ->
    $(".next-step").removeClass("disabled");
    file_content_type = data.result.files[0].file_content_type;
    switch file_content_type
      when "image/jpeg", "image/jpg", "image/png"
        $('.images-box, .uploaded_images').removeClass("hidden");
        $("#image_description").append(tmpl("tmpl-image-description",data.result));
        $("#uploaded_images").append(tmpl("tmpl-uploaded-images",data.result));
        count_images = $('#uploaded_images .uploaded_image').length
        $('span.total_uploaded_img').html("<b>Total: </b><span class='badge'>#{count_images}</span> ")
      when "audio/mp3"
        $('.audios-box, .uploaded_audio').removeClass("hidden");
        $("#audio_description").append(tmpl("tmpl-audio-description",data.result));
        $("#uploaded_audio").append(tmpl("tmpl-uploaded-audio",data.result));
        count_audios = $('#uploaded_audio tr').length
        $('span.total_uploaded_audio').html("<b>Total: </b><span class='badge'>#{count_audios}</span> ")
      when "video/mp4"
        $('.videos-box, .uploaded_video').removeClass("hidden");
        $("#video_description").append(tmpl("tmpl-video-description",data.result));
        $("#uploaded_video").append(tmpl("tmpl-uploaded-video",data.result));
        count_videos = $('#uploaded_video .video_box').length;
        $('span.total_uploaded_video').html("<b>Total: </b><span class='badge'>#{count_videos}</span> ")

    $('.tags').tagsinput({tagClass: "label label-primary"});

    $('.image_country').select2
      placeholder: 'Choose country',
      width: '100%',
      minimumInputLength: 0,
      allowClear: true,
      ajax:
        url: '/geobase/countries.json',
        quietMillis: 300,
        data: (term, page) ->
          { name_or_code_cont: term, page: page, per_page: 10, sorts: 'name asc'}
        results: (data, page) ->
          {
            results: $.map(data.items, (e) -> { id: e.id, text: e.name, data: {name: 1111} }),
            more: (page * 10) < data.total
          }
      initSelection: (element, callback) ->
        callback({id: element.data('id'), text: element.data('name')})
    .on "change", (e) ->
      $(this).closest('.location_data').find('.image_region1, .image_region2, .image_city').select2('data','')


    $('.image_region1').select2
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
            country_id_eq: $(this).closest('.location_data').find('.image_country').select2('val'),
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
        callback({id: element.data('id'), text: element.data('name')})
    .on "change", (e) ->
      $(this).closest('.location_data').find('.image_region2, .image_city').select2('data','')


    $('.image_region2').select2
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
            country_id_eq: $(this).closest('.location_data').find('.image_country').select2('val'),
            parent_id_eq: $(this).closest('.location_data').find('.image_region1').select2('val'),
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
        callback({id: element.data('id'), text: element.data('name')})
    .on "change", (e) ->
      $(this).closest('.location_data').find('.image_city').select2('data','')


    $('.image_city').select2
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
            country_id_eq: $(this).closest('.location_data').find('.image_country').select2('val'),
            primary_region_id_eq: $(this).closest('.location_data').find('.image_region1').select2('val'),
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
        callback({id: element.data('id'), text: element.data('name')})

    $('.video_country').select2
      placeholder: 'Select country',
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
            results: $.map(data.items, (e) -> { id: e.id, text: e.name }),
            more: (page * 10) < data.total
          }
      initSelection: (element, callback) ->
        callback({id: element.data('id'), text: element.data('name')})
    .on "change", (e) ->
      $(this).closest('.location_data').find('.video_region1, .video_region2, .video_city').select2('data','')


    $('.video_region1').select2
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
            country_id_eq: $(this).closest('.location_data').find(".video_country").select2('val'),
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
        callback({id: element.data('id'), text: element.data('name')})
    .on "change", (e) ->
      $(this).closest('.location_data').find('.video_region2, .video_city').select2('data','')

    $('.video_region2').select2
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
            country_id_eq: $(this).closest('.location_data').find(".video_country").select2('val'),
            parent_id_eq: $(this).closest('.location_data').find(".video_region1").select2('val'),
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
        callback({id: element.data('id'), text: element.data('name')})
    .on "change", (e) ->
      $(this).closest('.location_data').find('.video_city').select2('data','')


    $('.video_city').select2
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
            country_id_eq: $(this).closest('.location_data').find(".video_country").select2('val'),
            primary_region_id_eq: $(this).closest('.location_data').find(".video_region1").select2('val'),
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
        callback({id: element.data('id'), text: element.data('name')})

  $('body').on 'click','.cancel', (e) ->
    if ($('#local_import tr.template-upload').length == 1)
      $('.agreement, #local_import, button.cancel_all').addClass('hidden');
      $("#uploaded_files").empty();

  $('body').on 'click','button.cancel_all', (e) ->
    $('.agreement, #local_import').addClass('hidden');
    $("#uploaded_files").empty();

  $("#agreement").on "click", (e) ->
    if ($(this).prop('checked'))
      $(".start").removeClass("hidden");
    else
      $(".start").addClass("hidden");

  $('#image_files').on "click", ->
    if ($(this).prop('checked'))
      $('.image_select').show()
    else
      $('.image_select, #image_location_info').hide()
      $('#image_content_type, #country, #region1, #region2, #city').select2('data',"")

  $('#video_files').on "click", ->
    if ($(this).prop('checked'))
      $('.video_select').show();
      $('.videos-box').removeClass('hidden');
    else
      $('.video_select, #video_location_info').hide()
      $('#video_content_type, #video_country, #video_region1, #video_region2, #video_city').select2('data',"")
      $('.videos-box').addClass('hidden');

  $('#audio_files').on 'click', ->
    if ($(this).prop('checked'))
      $('.audio_select').show();
      $('.audios-box').removeClass('hidden');
    else
      $('.audio_select').hide();
      $('#audio_content_type').select2('val','');
      $('.audios-box').addClass('hidden');

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

  $("#image_content_type").on 'change', (e) ->
    if (e.val == '1' || e.val == '2')
      $('#image_location_info').show()
    else
      $('#image_location_info').hide()
      $(this).parent('.col-md-10').parent('.image_select').find('.image_type_block').hide();

  $("#video_content_type").on 'change', (e) ->
    if (e.val == '1')
      $('#video_location_info').show()
    else
      $('#video_location_info').hide()

  $('.nav-tabs > li a[title]').tooltip();
  $('a[data-toggle="tab"]').on 'show.bs.tab', (e) ->
    $target = $(e.target)
    if $target.parent().hasClass('disabled')
      return false
    return

  $('.next-step').click (e) ->
    $active = $('.wizard .nav-tabs li.active');
    $active.next().removeClass('disabled');
    nextTab($active);
    return

  $('.prev-step').click (e) ->
    $active = $('.wizard .nav-tabs li.active');
    prevTab($active);
    return

  nextTab = (elem) ->
    $(elem).next().find('a[data-toggle="tab"]').click();

  prevTab = (elem) ->
    $(elem).prev().find('a[data-toggle="tab"]').click();


window.shared_media_images_index =->
  $('#ransack_tags_name_cont').tagsinput({tagClass: "label label-primary"});

  $('.search-btn').on 'click', ->
    $('#search_form').submit()
  $(".image-preview").fancybox(fancybox_settings)

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

  $('#limit').select2
    placeholder: "Choose ..."
    allowClear: true

  $('#ransack_country_eq').select2
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
      $.get "/geobase/countries.json?id_eq=#{$('#ransack_country_eq').val()}", (dt) ->
        data = {id: element.val(), text: dt.items[0].name}
        callback(data)
  .on "change", (e) ->
    if (e && e.removed)
      $('#ransack_region1_eq, #ransack_region2_eq, #ransack_city_eq').select2("val","")

  $('#ransack_region1_eq').select2
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
          country_id_eq:  $('#ransack_country_eq').val(),
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
      $.get "/geobase/regions.json?country_id_eq=#{$('#ransack_country_eq').val()}&level_eq=1&id_eq=#{element.val()}", (dt) ->
        data = {id: element.val(), text: dt.items[0].name}
        callback(data)
  .on "change", (e) ->
    if (e && e.removed)
      $('#ransack_region2_eq, #ransack_city_eq').select2("val","")

  $('#ransack_region2_eq').select2
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
          country_id_eq: $('#ransack_country_eq').val(),
          parent_id_eq: $('#ransack_region1_eq').val(),
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
      $.get "/geobase/regions.json?level_eq=2&country_id_eq=#{$('#ransack_country_eq').val()}&id_eq=#{element.val()}", (dt) ->
        data = {id: element.val(), text: dt.items[0].name}
        callback(data)
  .on "change", (e) ->
    if (e && e.removed)
      $('#ransack_city_eq').select2("val","")

  $('#ransack_city_eq').select2
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
          country_id_eq: $('#ransack_country_eq').val(),
          primary_region_id_eq: $('#ransack_region1_eq').val(),
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
      $.get "/geobase/localities.json?id_eq=#{element.val()}", (dt) ->
        data = {id: element.val(), text: dt.items[0].name}
        callback(data)

  $("#image-clear-btn").on 'click', ->
    $('#search_conditions select').val('').select2('val','');
    $("#search_form input[type='text']").val("");
    $("#tags_name_cont").tagsinput('removeAll');
    $('#ransack_country_eq, #ransack_region1_eq, #ransack_region2_eq, #ransack_city_eq').select2('data','');


window.shared_media_images_dashboard =->
  $.get '/shared_media/images/region1_coverage.json', (data) ->
    country = new jvm.Map
      container: $('#country'),
      map: 'us_lcc_en',
      series:
        regions: [{
          values: data,
          scale: ['#C8EEFF', '#0071A4'],
          normalizeFunction: 'polynomial'
        }]
      regionsSelectable: true,
      regionsSelectableOne: true,
      regionLabelStyle:
        initial:
          fill: '#B90E32'
        hover:
          fill: 'black'
      labels:
        regions:
          render: (code) -> code.split('-')[1]
      onRegionTipShow: (e, el, code) ->
        el.html("#{el.html()}<br>(Images: #{data[code]})")
      onRegionClick: (event, code) ->
        $('#region').empty()
        $.get "/shared_media/images/region2_coverage.json?region1=#{code}", (data) ->
          new jvm.Map
            container: $('#region')
            map: "#{code.toLowerCase()}_lcc_en",
            series:
              regions: [{
                values: data,
                scale: ['#C8EEFF', '#0071A4'],
                normalizeFunction: 'polynomial'
              }]
            labels:
              regions:
                render: (code) ->
                  parts = code.split(' ')
                  parts.slice(1, parts.length - 1).join(' ')
            onRegionTipShow: (e, el, code) ->
              el.html("#{el.html()}<br>(Images #{data[code]})")
            regionLabelStyle:
              initial:
                fill: '#B90E32'
              hover:
                fill: 'black'
