window.artifacts_images_local_import =->
	fileUploadErrors = {
		maxFileSize: 'File is too big',
		minFileSize: 'File is too small',
		acceptFileTypes: 'Filetype not allowed',
		maxNumberOfFiles: 'Max number of files exceeded',
		uploadedBytes: 'Uploaded bytes exceed file size',
		emptyResult: 'Empty file upload result'
	};

	$('#tags').tagsinput({
		tagClass: "label label-success"
	});
	$('.bootstrap-tagsinput').css('width', '100%');
	$('.bootstrap-tagsinput input').css('width', '100%');

	$('.special_tag').on "change", ->
		special_tags = $('#special_tags')
		tags = special_tags.val().split(',')
		st_box = $(this)
		if st_box.is(":checked") is true then tags.push(st_box.val())
		else tags = tags.filter (e) -> e != st_box.val()
		special_tags.val(tags.join(',').replace(/^\s+|\soptions_for_blend+$/g, "").replace(/^,+|,+$/g, ""))

	$('#is_icon').on "click", ->
		$('#special_tags').val("");
		if ($('#is_icon').is(':checked'))
			$("#icon_tags").show()
		else
			$("#icon_tags, #general_box, #country_box, #region_box").hide()
			$('.tag_group').find("input[type=checkbox]").prop('checked', false)
	$('#general_special_tag').on 'click', ->
		if ($('#general_special_tag').is(':checked'))
			$('#general_box').show()
		else
			$('#special_tags').val("")
			$('#general_box').hide()
			$('#general_box').find("input[type=checkbox]").prop('checked', false)

	$('#Call_To_Action_Icon').on 'click', ->
		if ($('#Call_To_Action_Icon').is(':checked'))
			$('#call_to_action_box').show()
		else
			$('#call_to_action_box').hide()
			$('#call_to_action_box').find("input[type=checkbox]").prop('checked', false)

	$('#country_special_tag').on 'click', ->
		if ($('#country_special_tag').is(':checked'))
			$('#country_box').show()
		else
			$('#country_box').hide()
			$('#country_box').find("input[type=checkbox]").prop('checked', false)

	$('#region_special_tag').on 'click', ->
		if ($(this).is(':checked'))
			$('#region_box').show()
		else
			$('#region_box').hide()
			$('#region_box').find("input[type=checkbox]").prop('checked', false)

	# Initialize the jQuery File Upload widget:
	$('#fileupload').fileupload
		autoUpload: false
	.on 'fileuploadsubmit', (e, data) ->
    form_data = {client_id: $('#client_id').val(), tags: $('#tags').val(), special_tags: $('#special_tags').val(), use_for_landing_pages: $('#use_for_landing_pages').prop('checked')}
    form_data['reusable'] = $('#reusable').val()
    form_data['broadcaster_property'] = $('#broadcaster_property').val()
    form_data['country'] = $('#country').select2('data')?.text
    form_data['region1'] = $('#region1').select2('data')?.text
    form_data['region2'] = $('#region2').select2('data')?.text
    form_data['city'] = $('#city').select2('data')?.text
    form_data['notes'] = $('#notes').val()
    form_data['product_id'] = $('#product_id').val()
    form_data['rating'] = $('#rating').val()
    form_data['industry_id'] = $('#industry_image').val()
    arr = [];
    $.each $(".image_categories"), (k,e)->
      if ($(e).prop('checked'))
        arr.push($(e).val());
    form_data['image_categories'] = arr
    data.formData = form_data

	$('select').select2
    placeholder: 'Choose ...',
    width: '100%',
    minimumInputLength: 0,
    allowClear: true

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

  $('.image_rating').on 'click', (e) ->
    target_class = $(this).find("i").attr('class').split(' ')[1];
    data_index = $(this).data('index');
    $('.image_rating').find('i').removeClass('fa-star').addClass('fa-star-o');
    $('#rating').val(data_index + 1);
    for i in [0..data_index]
      $('a[data-index=' + i + ']').find('i').removeClass('fa-star-o').addClass('fa-star');

  $('.image_rating').on "dblclick", ()->
    $(this).find('i').removeClass('fa-star').addClass('fa-star-o');
    $('#rating').val(0);

  $('#industry_image').select2
    dropdownCssClass: 'bigdrop',
    placeholder: 'Select industry by NAICS industry code or by typing industry name',
    allowClear: true,
    ajax:
      url: '/industries/tools/json_list',
      dataType: 'json',
      data: (term, page) ->
        {
          id: $(this).val(),
          q: term
        }
      results: (data, page) ->
        {
          results: data
        }
    initSelection: (item, callback) ->
      id = item.val()
      if(id != "")
        $.ajax('/industries/tools/json_list',{
          data: { id: id },
          dataType: 'json'
          }).done( (data) ->
            callback(data[0])
            )
    formatResult: (item) ->
      item.text
    formatSelection: (item) ->
      item.text
    escapeMarkup: (m) ->
      m
  $('#industry_image').on "click", ->
    $(this).select2("open")
