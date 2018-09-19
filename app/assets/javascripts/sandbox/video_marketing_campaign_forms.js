//= require 'jquery_nested_form'
//= require fancybox2
var ready = function () {
  fancybox_settings = {
    helpers: {
      title : {
        type : 'float'
      }
    }
  }
  $(".image-preview").fancybox(fancybox_settings);

  $('.iCheck-helper').iCheck({
    checkboxClass: 'icheckbox_square-blue',
    radioClass: 'iradio_square-blue'
  });

  var colors = ["primary"];
  var cities_array = [];
  var deleted_stock_images_array = [];
	var deleted_stock_image_templates_array = [];

  $('#cities_list .city-div').each(function(){
    cities_array.push($(this).data("id").toString());
  });
  collectCities();

  function colorTags(){
    var tags = $('div#tag_list_block .tag');
    for(var i = 0; i < tags.length; i++){
      tags[i].className = "tag label label-tags label-" + colors[i % (colors.length)];
    }
  }

  function countKeywords(){
    if ($("#tag_list_block div.bootstrap-tagsinput").length > 0) {
      tag_list_count = 0;
      var tag_list_block = $("#tag_list_block");
      var tag_list_block_input = $("#tag_list_block div.bootstrap-tagsinput");
      var tag_list = $("#video_marketing_campaign_form_tag_list").val();
      var tag_list_array = tag_list.split(",").filter(Boolean);
      tag_list_count = tag_list_array.length;
      $("#tag_list_count").text(tag_list_count);
    }
  }

  if ($("#stock_images_results").length > 0) {
    //collectDeletedStockImages();
    $.each($('#video_marketing_campaign_form_deleted_stock_images').val().toString().replace('{', '').replace('}', '').split(","), function (index, value) {
      deleted_stock_images_array.push(value.toString());
    });
    vmf_path = $(".edit_video_marketing_campaign_form").first().attr("action").split("?public_profile_uuid=")[0];
    $.get(vmf_path + "/stock_images.js");
    $('.page, .next, .first, .prev, .next_page').on('click', function () {
      $('.animationload').show();
    });
    $(document).on('click', '.delete-image', function () {
      artifacts_image_id = $(this).closest('.artifacts_image').data("id");
      if (artifacts_image_id != '' && artifacts_image_id != undefined && $.inArray(artifacts_image_id, deleted_stock_images_array) === -1) {
        deleted_stock_images_array.push(artifacts_image_id);
        collectDeletedStockImages();
      }
      $(this).closest(".artifacts_image").addClass("disabled-block");
  	});
  }

	if ($("#stock_image_templates_results").length > 0) {
    $.each($('#video_marketing_campaign_form_deleted_stock_image_templates').val().toString().replace('{', '').replace('}', '').split(","), function (index, value) {
      deleted_stock_image_templates_array.push(value.toString());
    });
    vmf_path = $(".edit_video_marketing_campaign_form").first().attr("action").split("?public_profile_uuid=")[0];
    $.get(vmf_path + "/stock_image_templates.js");
    $('.page, .next, .first, .prev, .next_page').on('click', function () {
      $('.animationload').show();
    });
    $(document).on('click', '.delete-image-template', function () {
      image_template_id = $(this).closest('.artifacts_image').data("id");
      if (image_template_id != '' && image_template_id != undefined && $.inArray(image_template_id, deleted_stock_image_templates_array) === -1) {
        deleted_stock_image_templates_array.push(image_template_id);
        collectDeletedStockImageTemplates();
      }
      $(this).closest(".artifacts_image").addClass("disabled-block");
  	});
  }

  function collectDeletedStockImages(){
    $('#video_marketing_campaign_form_deleted_stock_images').val('{' + deleted_stock_images_array + '}');
  }

	function collectDeletedStockImageTemplates(){
    $('#video_marketing_campaign_form_deleted_stock_image_templates').val('{' + deleted_stock_image_templates_array + '}');
  }

	function categorySidebarMenuClick(category_block_selector){
		cur_list_group_item = $(this).closest('.list-group-item')
		list_group = cur_list_group_item.closest('.list-group')
		list_group.find('.list-group-item').removeClass('active')
		cur_list_group_item.addClass('active')
		$('.animationload').show();
	}

	$('#stock_images_categories_block a').on('click', categorySidebarMenuClick);
	$('#stock_image_templates_categories_block a').on('click', categorySidebarMenuClick);

  if ($("#video_marketing_campaign_form_distributor_names_csv").length > 0) {
    var distributor_items = [];
    $.each($('#distributors_list').val().split('<sep/>'), function( index, value ) {
      distributor_items.push({'id': value, 'text': value});
    });
    function split( val ) {
      return val.split( /,\s*/ );
    }
    function extractLast( term ) {
      return split( term ).pop();
    }
    // $('#video_marketing_campaign_form_distributor_name').autocomplete({
    //     minLength: 1,
    //     source: function (request, response) {
    //         var term = request.term;
    //
    //         // substring of new string (only when a ';' is in string)
    //         if (term.indexOf('; ') > 0) {
    //             var index = term.lastIndexOf('; ');
    //             term = term.substring(index + 2);
    //         }
    //
    //         // regex to match string entered with start of suggestion strings
    //         var re = $.ui.autocomplete.escapeRegex(term);
    //         var matcher = new RegExp('^' + re, 'i');
    //         var regex_validated_array = $.grep(distributor_items, function (item, index) {
    //             return matcher.test(item);
    //         });
    //
    //         // pass array 'regex_validated_array' to the response and
    //         // `extractLast()` which takes care of the comma separation
    //
    //         response($.ui.autocomplete.filter(regex_validated_array,
    //              extractLast(term)));
    //     },
    //     focus: function () {
    //         return false;
    //     },
    //     select: function (event, ui) {
    //         var terms = split(this.value);
    //         terms.pop();
    //         terms.push(ui.item.value);
    //         terms.push('');
    //         this.value = terms.join('; ');
    //         return false;
    //     }
    // });

    $('#video_marketing_campaign_form_distributor_names_csv').select2({
  		multiple: true,
  		data: distributor_items,
  		width: '100%',
      placeholder: function(){
        $(this).data('placeholder');
      },
  		createSearchChoice: function (term, data) { return { id: term, text: term }; },
  		initSelection: function (element, callback) {
  			var values = $.map($(element).val().split(/\s*,\s*/), function (v) {
  				return { id: v, text: v };
  			});
  			callback(values);
  		}
  	});
    $('#distributor_names_arrow_down').on('click', function(){
      $("#video_marketing_campaign_form_distributor_names_csv").select2("open");
    });
  }

  if ($("#industries_json").length > 0) {
    var industries_json = JSON.parse($("#industries_json").val());
    function update_brands_list(industry_id){
      brands = industries_json["id_" + industry_id];
      brands_select = $('#brand_id');
      brands_select.empty();
      brands_select.append($("<option></option>"))
      $.each(brands, function( index, value ) {
        brands_select.append($("<option></option>").attr("value", value).text(value))
      });
    }
    $('.industry-chooser').on('click', function (e) {
      $('.industry_block').hide();
      $('.industry_blocks_header').hide();
      $(this).hide();
      $(this).closest('.industry_block').show();
      $(this).closest('.industry_block').css('margin',"0px");
      $(this).closest('.industry_block').find('.change-btn').first().show();
      $(this).closest('.industry_block').first().css("width", "100%");
      $(this).closest('.industry_block').find('.col').first().css("width",  "10%");
      console.log($(this).data("industry-id"));
      $('#industry_id').val($(this).data("industry-id"));
      //$('#industry_selection').hide();
      $('#step_0').removeClass("active").addClass("success");
      $('#step_1').addClass("active");
      $('#search_filters').show();
      $('#search_results_help').show();
      $('.main-body').removeClass("step-0").addClass("step-1");
      $('.wrap1').removeClass("step-0").addClass("step-1");
      $('.image-container').removeClass("step-0").addClass("step-1");

      //update_brands_list($(this).data("industry_id"));
    });
    // $("#industry_id").on("change", function (){
    //   update_brands_list($(this).val());
    // });
  }

  $('.change-btn').on("click", function () {
    $(this).closest('.industry_block').first().css("width", "31%");
    $(this).closest('.industry_block').find('.col').first().css("width",  "25%");
    $(this).hide();
    $('.industry_block').css("margin", "0px 13px 0px 13px");
    $('#search_filters').hide();
    $('.industry-chooser').show();
    $('.industry_block').show();
    $('.industry_blocks_header').show();
    $('#step_0').addClass("active").removeClass("success");
    $('#step_1').removeClass("active");
    $('#search_results_content').hide();
    $('#search_results_help').hide();
    $("#search_results").removeClass("col-md-9").addClass("col-md-4");
    $("#search_filters").removeClass("col-md-3").addClass("col-md-4");
    $('.main-body').removeClass("step-1").addClass("step-0");
    $('.wrap1').removeClass("step-1").addClass("step-0");
    $('.image-container').removeClass("step-1").addClass("step-0");
  });

  $("#video_marketing_campaign_form_tag_list").tagsinput();
  $(".bootstrap-tagsinput input").css('width', '');
  $("#video_marketing_campaign_form_tag_list").on("change", function(){
    countKeywords();
    colorTags();
  });

	function collectPhones () {
		var phone_numbers = '';
    var contact_phone_numbers = '';
    var representative_phone_numbers = ''

		$('#phones_block div.phone-row').each(function () {
			phone_type = $(this).find('.phone-type').val();
			phone = $(this).find('.phone').val().trim();
			if (phone != '') phone_numbers += phone_type + phone + ','
		});

    $('#contact_phones_block div.phone-row').each(function () {
			phone_type = $(this).find('.phone-type').val();
			phone = $(this).find('.phone').val().trim();
			if (phone != '') contact_phone_numbers += phone_type + phone + ','
		});

    $('#representative_phones_block div.phone-row').each(function () {
			phone_type = $(this).find('.phone-type').val();
			phone = $(this).find('.phone').val().trim();
			if (phone != '') representative_phone_numbers += phone_type + phone + ','
		});

		$('#video_marketing_campaign_form_company_phones_csv').val(phone_numbers);
    $('#video_marketing_campaign_form_contact_phones_csv').val(contact_phone_numbers);
    $('#video_marketing_campaign_form_representative_phones_csv').val(representative_phone_numbers);
	}

	function phone_mask () {
		$('div.phone-row .phone').each(function () {
			$(this).inputmask('mask', { 'mask': '(999)-999-9999 [x99999]' });
		});
    $('#video_marketing_campaign_form_primary_phone').inputmask('mask', { 'mask': '(999)-999-9999 [x99999]' });
	}

	$('#phones_add').on('click', function () {
		var phone_types_example = $('#phones_block .phone-types-example')[0];
		var phone_row = '<div class="input-group phone-row">' + phone_types_example.innerHTML + '<input type="text" class="form-control phone" placeholder="Phone Number"><span class="input-group-btn"><a href="javascript://" class="btn btn-default delete-link" title="Delete"><i class="fa fa-times"></i></a></span></div>';
		$('#phones_block').append(phone_row);
		phone_mask();
	});

  $('#representative_phones_add').on('click', function () {
		var phone_types_example = $('#representative_phones_block .phone-types-example')[0];
		var phone_row = '<div class="input-group phone-row">' + phone_types_example.innerHTML + '<input type="text" class="form-control phone" placeholder="Phone Number"><span class="input-group-btn"><a href="javascript://" class="btn btn-default delete-link" title="Delete"><i class="fa fa-times"></i></a></span></div>';
		$('#representative_phones_block').append(phone_row);
		phone_mask();
	});

  $('#contact_phones_add').on('click', function () {
		var phone_types_example = $('#contact_phones_block .phone-types-example')[0];
		var phone_row = '<div class="input-group phone-row">' + phone_types_example.innerHTML + '<input type="text" class="form-control phone" placeholder="Phone Number"><span class="input-group-btn"><a href="javascript://" class="btn btn-default delete-link" title="Delete"><i class="fa fa-times"></i></a></span></div>';
		$('#contact_phones_block').append(phone_row);
		phone_mask();
	});

  $('.add_nested_fields').on('mouseup', function () {
    setTimeout(function(){
      var el = $('#summary_points_section textarea:last');
      if (el.val() == '    ' || el.val() == '          ') {
        el.val('');
      }
    }, 100);
    setTimeout(function(){
      var el = $('#descriptions textarea:last');
      if (el.val() == '    ' || el.val() == '          ') {
        el.val('');
      }
    }, 100);
  });

	$(document).on('click', '#phones_block .delete-link', function () {
		$(this).parent().parent().remove();
	});

  $(document).on('click', '#contact_phones_block .delete-link', function () {
    $(this).parent().parent().remove();
  });

  $(document).on('click', '#representative_phones_block .delete-link', function () {
    $(this).parent().parent().remove();
  });

	$('#video_marketing_campaign_form_zipcode').on('change', function () {
    if ($(this).val() != '') {
      $.ajax({
  			type: 'GET',
  			url: '/geolocation/zip_code/' + $('#video_marketing_campaign_form_zipcode').val()
  		}).done(function (response) {
  			$('#video_marketing_campaign_form_locality').val(response.locality);
  			$('#video_marketing_campaign_form_region').val(response.region);
  			$('#video_marketing_campaign_form_country').val(response.country);
  		});
    }
	});

  if ($('.new_video_marketing_campaign_form').length > 0) {
    $('#video_marketing_campaign_form_zipcode').trigger('change');
  }

  $('.new_video_marketing_campaign_form input.form-control, .edit_video_marketing_campaign_form input.form-control').on('keyup keypress', function(e) {
    var keyCode = e.keyCode || e.which;
    if (keyCode === 13) {
      e.preventDefault();
      return false;
    }
  });

	if (isForm('video_marketing_campaign_form', true, true)) {
    if ($('#video_marketing_campaign_form_company_phones_csv').val() == '') $('#phones_add').trigger('click');
    if ($('#video_marketing_campaign_form_contact_phones_csv').val() == '') $('#contact_phones_add').trigger('click');
    if ($('#video_marketing_campaign_form_representative_phones_csv').val() == '') $('#representative_phones_add').trigger('click');
		collectPhones();
		phone_mask();
    countKeywords();
    colorTags();
    $('.select2-container').addClass('form-control');
		$('.new_video_marketing_campaign_form, .edit_video_marketing_campaign_form').submit(function (e) {
			window.onbeforeunload = '';
			collectPhones();
		});
	}

  // Counter characters
	function calc_one (text_area) {
		text_area.closest('.form-group').find('.calc-one').text(text_area.val().length);
	}

	$('fieldset textarea').each(function () {
		calc_one($(this));
	});

	$(document).on('keyup', 'fieldset textarea', function () {
		calc_one($(this));
	});

  $(document).on('change', 'fieldset textarea', function () {
		calc_one($(this));
	});

  var selected_country_id = $('#country_default').data('id');
  var selected_country_name = $('#country_default').data('name');

  $('#country').val(selected_country_id);

  $('#country').select2({
    placeholder: 'Choose country',
    width: '100%',
    minimumInputLength: 0,
    allowClear: false,
    ajax: {
      url: '/geobase/countries.json',
      quietMillis: 300,
      data: function(term, page) {
        return {
          name_or_code_cont: term,
          page: page,
          per_page: 10,
          sorts: 'name asc'
        };
      },
      results: function(data, page) {
        return {
          results: $.map(data.items, function(e) {
            return {
              id: e.id,
              text: e.name
            };
          }),
          more: (page * 10) < data.total
        };
      }
    },
    initSelection: function(element, callback) {
      var data;
      data = {
        id: selected_country_id,
        text: selected_country_name
      };
      return callback(data);
    }
  });

  $('#country').prop("disabled", true);

  $('#region1').select2({
    placeholder: 'Filter by state',
    width: '100%',
    minimumInputLength: 0,
    allowClear: true,
    ajax: {
      url: '/geobase/regions.json',
      quietMillis: 300,
      data: function(term, page) {
        return {
          name_or_code_cont: term,
          level_eq: 1,
          country_id_eq: $('#country').val(),
          page: page,
          per_page: 10,
          sorts: 'name asc'
        };
      },
      results: function(data, page) {
        return {
          results: $.map(data.items, function(e) {
            return {
              id: e.id,
              text: e.name
            };
          }),
          more: (page * 10) < data.total
        };
      }
    }
  });

  $('#city').select2({
    placeholder: 'Choose locality',
    width: '100%',
    minimumInputLength: 0,
    allowClear: true,
    ajax: {
      url: '/geobase/localities.json',
      quietMillis: 300,
      data: function(term, page) {
        return {
          name_or_code_cont: term,
          country_id_eq: $('#country').val(),
          primary_region_id_eq: $('#region1').val(),
          page: page,
          per_page: 10,
          sorts: ['population desc', 'name asc']
        };
      },
      results: function(data, page) {
        return {
          results: $.map(data.items, function(e) {
            return {
              id: e.id,
              text: e.name + ', ' + e.primary_region.code.split('<sep/>')[0].replace('US-', ''),
              population: e.population
            };
          }),
          more: (page * 10) < data.total
        };
      }
    }
  }).on('change', function(){
    if ($(this).val() != '' && $(this).val() != undefined) {
      if ($.inArray($(this).val(), cities_array) === -1) {
        cities_array.push($(this).val());
        city_arr = $(this).select2('data').text.split(", ");
        $("#cities_list").append("<div class='col-md-4 city-div' data-id='" + $(this).val() + "' data-population='" + $(this).select2('data').population + "'><div class='state-block pull-left'>" + city_arr[1] + "</div><div class='locality-block'><div>" + city_arr[0] + "</div><div class='population' title='Population'>" + addCommas($(this).select2('data').population) + " <i class='fa fa-user'></i></div></div><a href='javascript://'' class='btn btn-default btn-xs delete-city-link pull-right' title='Delete'><i class='fa fa-times'></i></a></div>");
        $("#selected_localities_count").effect("highlight", {color: '#79ce7a'}, 3000);
        collectCities();
      } else {
        $("#selected_localities_count").effect("highlight", {color: '#ffa700'}, 3000);
      }
      $('#city').select2('val', '');
    }
  });

  $('#region1').on('change', function() {
    $('#region2').select2('val', '');
    $('#city').select2('val', '');
  });

  function addCommas(nStr) {
    if (nStr != undefined || nStr != '') {
      nStr += '';
      x = nStr.split('.');
      x1 = x[0];
      x2 = x.length > 1 ? '.' + x[1] : '';
      var rgx = /(\d+)(\d{3})/;
      while (rgx.test(x1)) {
              x1 = x1.replace(rgx, '$1' + ',' + '$2');
      }
      return x1 + x2;
    } else {
      return "-"
    }
  }

  $(document).on('click', '.delete-city-link', function () {
    if (window.confirm("Are you sure you want to delete this location?")) {
      city_id = $(this).parent().data('id').toString();
      index = cities_array.indexOf(city_id);
      if (index > -1) {
        cities_array.splice(index, 1);
    	  $(this).closest(".city-div").remove();
        collectCities();
      }
    }
	});

  $('.primary-brand').on('ifChecked', function(event){
    $('.brand-frame').removeClass('brand-frame-selected');
    $('.checkbox').removeClass('disabled-block');
    $('#video_marketing_campaign_form_brands_' + $(this).val()).closest('.checkbox').addClass('disabled-block');
    $('#video_marketing_campaign_form_brands_' + $(this).val()).iCheck('uncheck');
    $(this).closest(".claim_option_brand").first().find(".brand-frame").first().addClass('brand-frame-selected');
    $("#brands_modal_submit").removeClass("disabled");
  });

  $('#other_brands').on('ifChecked', function(event){
    $('#video_marketing_campaign_form_other_brands').show();
    $('#other_brands_label').show();
  });

  $('#other_brands').on('ifUnchecked', function(event){
    $('#video_marketing_campaign_form_other_brands').hide();
    $('#other_brands_label').hide();
    $('#video_marketing_campaign_form_other_brands').val('');
  });

  $('#video_marketing_campaign_form_no_social_links').on('ifChecked', function(event){
    $('#video_marketing_campaign_form_has_youtube_channel_false').iCheck('check');
    $('#social_links').hide();
  });

  $('#video_marketing_campaign_form_no_social_links').on('ifUnchecked', function(event){
    $('#video_marketing_campaign_form_has_youtube_channel_true').iCheck('uncheck');
    $('#video_marketing_campaign_form_has_youtube_channel_false').iCheck('uncheck');
    $('#social_links').show();
  });

  $('#video_marketing_campaign_form_youtube_url').on('change', function(){
    if ($('#video_marketing_campaign_form_youtube_url').val() != '') {
      $('#video_marketing_campaign_form_has_youtube_channel_true').iCheck('check');
    }
  });

  $('#video_marketing_campaign_form_no_website_true').on('ifChecked', function(event){
    $('#video_marketing_campaign_form_website').val('');
  });

  $('#video_marketing_campaign_form_website').on('change', function(){
    if ($('#video_marketing_campaign_form_website').val() != '') {
      $('#video_marketing_campaign_form_no_website_false').iCheck('check');
    }
  });

  $('#video_marketing_campaign_form_use_stock_images').on('ifChecked', function(event){
    $("#stock_images_block").removeClass("disabled-block");
  });

  $('#video_marketing_campaign_form_use_stock_images').on('ifUnchecked', function(event){
    $("#stock_images_block").addClass("disabled-block");
  });

	$('#video_marketing_campaign_form_use_stock_image_templates').on('ifChecked', function(event){
    $("#stock_image_templates_block").removeClass("disabled-block");
  });

  $('#video_marketing_campaign_form_use_stock_image_templates').on('ifUnchecked', function(event){
    $("#stock_image_templates_block").addClass("disabled-block");
  });

  function collectCities(){
    if (cities_array.length > 0) {
      $('#localities_missing_text').hide();
    } else {
      $('#localities_missing_text').show();
    }
    if (cities_array.length == parseInt($("#localities_limit").val())) {
      $('#locality_filters').addClass('disabled-block');
    } else {
      $('#locality_filters').removeClass('disabled-block');
    }
    $('#selected_localities_count').text(cities_array.length);
    $('#video_marketing_campaign_form_cities').val('{' + cities_array + '}');
    population_total_array = [];
    $(".city-div").each(function (){
      population_total_array.push($(this).data("population"));
    });
    population_sum = 0;
    for (i = 0; i < population_total_array.length; i++) {
      population_sum += population_total_array[i]
    }
    $("#population_total").text(addCommas(population_sum));
  }

  $("#filters_form #id").on("change", function () {
    if ($(this).val() == '') {
      $("#filters_form #name").attr("required", "required");
      $("#filters_form #phone").attr("required", "required");
    } else {
      $("#filters_form #name").removeAttr("required");
      $("#filters_form #phone").removeAttr("required");
    }
  });

  $("#filters_form").on("submit", function() {
    $(".animationload").show();
  });

  $("#filters_form .phone-number").inputmask('mask', { 'mask': '(999)-999-9999 [x99999]' });

  $("#info_next_btn").on('click', function(){
    $('.panel-collapse').collapse('hide');
    $('#brands_selection_section').collapse('show');
  });

  $("#brands_selection_back_btn").on('click', function(){
    $('.panel-collapse').collapse('hide');
    $('#info_section').collapse('show');
  });

  $("#brands_selection_next_btn").on('click', function(){
    $('.panel-collapse').collapse('hide');
    $('#address_section').collapse('show');
  });

  $("#address_next_btn").on('click', function(){
    $('.panel-collapse').collapse('hide');
    $('#representative_section').collapse('show');
  });

  $("#address_back_btn").on('click', function(){
    $('.panel-collapse').collapse('hide');
    $('#brands_selection_section').collapse('show');
  });

  $("#representative_next_btn").on('click', function(){
    $('.panel-collapse').collapse('hide');
    $('#social_links_section').collapse('show');
  });

  $("#representative_back_btn").on('click', function(){
    $('.panel-collapse').collapse('hide');
    $('#address_section').collapse('show');
  });

  $("#social_links_back_btn").on('click', function(){
    $('.panel-collapse').collapse('hide');
    $('#representative_section').collapse('show');
  });

  $("#packages_next_btn").on('click', function(){
		$('.panel-collapse').collapse('hide');
		youtube_section = $('#youtube_section');
		if($('.selected-package-btn').attr('data-is-youtube-package') == 'true'){
			youtube_section.closest('.panel').show();
			$('#youtube_section').collapse('show');
		} else{
			youtube_section.closest('.panel').hide();
			$('#contact_section').collapse('show');
		}
  });

  $('#bind_youtube_channel_back_btn').on('click', function(){
    $('.panel-collapse').collapse('hide');
    $('#packages_section').collapse('show');
  });

  $('#bind_youtube_channel_next_btn').on('click', function(){
    $('.panel-collapse').collapse('hide');
    $('#contact_section').collapse('show');
  });

  $("#contact_back_btn").on('click', function(){
    $('.panel-collapse').collapse('hide');
    if($('.selected-package-btn').attr('data-is-youtube-package') == 'true'){
      youtube_section.closest('.panel').show();
      $('#youtube_section').collapse('show');
    } else{
      $('#packages_section').collapse('show');
    }
  });

  $("#contact_next_btn").on('click', function(){
    $('.panel-collapse').collapse('hide');
    $('#localities_section').collapse('show');
  });

  $("#localities_back_btn").on('click', function(){
    $('.panel-collapse').collapse('hide');
    $('#contact_section').collapse('show');
  });
  $("#localities_next_btn").on('click', function(){
    $('.panel-collapse').collapse('hide');
    $('#brands_section').collapse('show');
  });

	$("#youtube_back_btn").on('click', function(){
    $('.panel-collapse').collapse('hide');
    $('#packages_section').collapse('show');
  });
  $("#youtube_next_btn").on('click', function(){
    $('.panel-collapse').collapse('hide');
    $('#localities_section').collapse('show');
  });

  $("#brands_back_btn").on('click', function(){
    $('.panel-collapse').collapse('hide');
    $('#localities_section').collapse('show');
  });
  $("#brands_next_btn").on('click', function(){
    $('.panel-collapse').collapse('hide');
    $('#logo_reveal_section').collapse('show');
  });
  $("#logo_reveal_back_btn").on('click', function(){
    $('.panel-collapse').collapse('hide');
    $('#brands_section').collapse('show');
  });

  $('.panel-primary').find('.panel-collapse').collapse({toggle: false});
  $('.panel-danger').find('.panel-collapse').collapse({toggle: false});

  if ($('.panel-danger').length > 0) {
    $('.panel-danger').find('.panel-collapse').first().collapse('show');;
  } else {
    $('#info_section').collapse('show');
    $('#packages_section').collapse('show');
  }

  $('#more_primary_brands').on('click', function(){
    $('.primary-brand-div').show();
    $('#more_secondary_brands').trigger('click');
    $(this).hide();
    $("#more_primary_brands_span").hide();
  });

  $('#more_secondary_brands').on('click', function(){
    $('.secondary-brand-div').show();
    $(this).hide();
  });

  $('.brand-frame').on('click', function(){
    $(this).closest('.claim_option_brand').first().find('.checkbox').first().iCheck('toggle');
  });

  function select_package(el) {
    id_value = el.data("id");
    package_name = el.data("name");
    package_price_formatted = el.data("price-formatted");
    package_cart_description = el.data("cart-description");
    locations = el.data("locations");
    $('#localities_limit_count').text(locations);
    $('#package_name').text(package_name);
    $('#package_price').text(package_price_formatted);
    $('#package_cart_description').text(package_cart_description);
    $('#cart_total').text(package_price_formatted);
    $('.active-package-btn').removeClass('selected-package-btn');
    $('.active-package-btn').text('SELECT PACKAGE');
    el.addClass('selected-package-btn');
    el.text('SELECTED');
    $("#localities_limit").val(locations);
    if ($('#video_marketing_campaign_form_package_type').val() != id_value.toString()) {
      if (cities_array.length > 0) {
        if (cities_array.length > locations) {
          $(".city-div").slice(-1 * (cities_array.length - locations)).remove();
          cities_array.splice(0, cities_array.length - locations);
        }
        console.log("after: " + cities_array.length);
        collectCities();
      }
    }
    $('#video_marketing_campaign_form_package_type').val(id_value);
    if ($('.selected-package-btn').attr('data-is-youtube-package') == 'true'){
      $('#youtube_heading a').first().attr("onclick", "$('#packages_next_btn').trigger('click');");
      $('#packages_heading a').first().attr("onclick", "$('#bind_youtube_channel_back_btn').trigger('click')");
    } else {
      $('#packages_heading a').first().attr("onclick", "$('#contact_back_btn').trigger('click')");
    }
  }

  $('.active-package-btn').on('click', function(){
    select_package($(this));
    $('#packages_next_btn').trigger('click');
    $('#contact_help_block').addClass("help-block-warning");
  });
  if ($('.selected-package-btn').length > 0) {
    select_package($('.selected-package-btn'));
  }

  //$('.selected-package-btn').trigger('click');

  // $("#filter-apply").on('click', function (e) {
  //   e.preventDefault();
  //   var name = $("#name").val();
  //   var phone = $("#phone").val();
  //
  //   if (name.length > 0 && phone.length > 0) {
  //     $('.animationload').show(); $('#dealer_ids').val('');
  //     $("#filters_form").submit();
  //   } else {
  //     if (name.length == 0) {
  //       console.log("missing name");
  //     }
  //     if (phone.length == 0) {
  //       console.log("missing phone");
  //     }
  //   }
  // });

  $(document).on("keypress", "#filters_form", function(event) {
    return event.keyCode != 13;
  });

	/*Youtube Channell block*/
	$('#bind_new_yt_channel_btn').click(function(){
		$('#refresh_token_block').toggle();
	})
}

$(document).ready(ready);
$(document).on('page:load', ready);

window.sandbox_video_marketing_campaign_forms_edit = function(){

  $('#fileupload').fileupload({
    url: "upload_client_images",
    type: 'PATCH',
    autoUpload: false,
    dropZone: $('#dropzone')
  }).on('fileuploaddone', function(e, data){
    $('#client_images_results').prepend("<div class = 'col-md-2 qt'><div class='u-photo-block'><a class='u-photo-remove' href='client_images_destroy/" + data.result.files[0].id + "' data-method='delete' data-remote='true' data-id=" + data.result.files[0].id + "><i class='fa fa-times fa-2x'></i></a><img alt='' class='u-photo' src=" + data.result.files[0].url + "></div></div>");
    if ($('body').find($('.qt')).length > 24){
      $('.qt:last').remove();
    }
  });

  $('#licenseupload').fileupload({
    url: "upload_license_file",
    type: 'PATCH',
    autoUpload: false,
    dropZone: false,
    uploadTemplateId: 'template-upload-license',
    downloadTemplateId: 'template-download-license'
  }).on('fileuploaddone', function(e, data){
    var license_proof_file_id = data.result.files[0].id;
    var license_proof_file_name = data.result.files[0].name;

    if ($('.uploaded_image_id').length > 0){
      var uploaded_images_ids = [];
      $.each($('.uploaded_image_id'), function(i,e){
        uploaded_images_ids.push(e.value);
      });

      $.ajax({
        url: "associate_license_to_images",
        type: 'POST',
        data: {'uploaded_images_ids': uploaded_images_ids, 'license_proof_file_id': license_proof_file_id}
      });
    }

  });

  $('.choose_license_file_link').on('click', function(e){
    $('.upload_license_proof_file_field').click();
  })

  $('.upload_new_file_link').on("click", function(e){
    $('.upload_new_file_field').click();
  })

  $('.choose_file_link').on('click', function(e){
    $(this).closest('.choose_file_block').find('.file_field').click();
  })

  $('#modal_for_upload').on('hidden.bs.modal', function(){
    $('.template-upload').remove();
    $('.template-download').remove();
  });

	//bootstrap accordion collapse fix
	$('.collapse').on('show.bs.collapse', function () {
    $('.collapse.in').each(function(){
        $(this).collapse('hide');
    });
  });

	$('[role=accordion-btn-prev],[role=accordion-btn-next]').on('click', function(){
		cur_btn = $(this);
		active_tab = cur_btn.closest('.panel');
		target_tab = (cur_btn.attr('role') == 'accordion-btn-prev') ? active_tab.prev('.panel') : active_tab.next('.panel');
		active_tab.closest('.panel-group').find('.panel-collapse.collapse.in')
		target_tab.find('.panel-collapse').collapse('show');
	});
}


window.sandbox_video_marketing_campaign_forms_landing = function(){
  var ready = function () {
    $('html, body').animate({scrollTop: $('#landing_wrap').position().top - 70}, 'slow');

    fancybox_landing_video_settings = {
      type: 'iframe',
      width		: '90%',
      maxWidth	: 1170,
      minHeight: 658,
      iframe: {
        scrolling: 'auto',
        preload: false
      }
    }
    $('#btn_watch').fancybox(fancybox_landing_video_settings);
    if ($("#btn_watch").data("play") == true) {
      $('#btn_watch').trigger('click');
    }
  }
  $(document).ready(ready);
  $(document).on('page:load', ready);
}
