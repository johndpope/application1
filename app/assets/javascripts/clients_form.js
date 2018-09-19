//= require 'jquery_nested_form'
var ready = function () {
  var colors = ["primary"];

  function colorTags(){
    var tags = $('div#tag_list_block .tag');
    for(var i = 0; i < tags.length; i++){
      tags[i].className = "tag label label-tags label-" + colors[i % (colors.length)];
    }
  }

  function countKeywords(){
    tag_list_count = 0;
    var tag_list_block = $("#tag_list_block");
    var tag_list_block_input = $("#tag_list_block div.bootstrap-tagsinput");
    var tag_list = $("#client_tag_list").val();
    var tag_list_array = tag_list.split(",").filter(Boolean);
    tag_list_count = tag_list_array.length;
    $("#tag_list_count").text(tag_list_count);
  }

  $("#client_tag_list").tagsinput();
  $(".bootstrap-tagsinput input").css('width', '');
  $("#client_tag_list").on("change", function(){
    countKeywords();
    colorTags();
  });
  countKeywords();
  colorTags();

	function collectPhones () {
		var phone_numbers = '';

		$('#phones_block div.phone-row').each(function () {
			var phone_type = $(this).find('.phone-type').val();
			var phone = $(this).find('.phone').val().trim();
			if (phone != '') phone_numbers += phone_type + phone + ','
		});

		$('#client_phones_csv').val(phone_numbers);
	}

	function phone_mask () {
		$('div.phone-row .phone').each(function () {
			$(this).inputmask('mask', { 'mask': '(999)-999-9999 [x99999]' });
		});
	}

	$('#phones_add').on('click', function () {
		var phone_types_example = $('#phones_block .phone-types-example')[0];
		var phone_row = '<div class="input-group phone-row"><span class="input-group-addon" style="background-color: #43B51F; border: 1px solid #43B51F;"><i class="fa fa-phone"></i></span>' + phone_types_example.innerHTML + '<input type="text" class="form-control phone" placeholder="Phone Number"><span class="input-group-btn"><a href="javascript://" class="btn btn-default delete-link" title="Delete"><i class="fa fa-times"></i></a></span></div>';
		$('#phones_block').append(phone_row);
		phone_mask();
	});

	$(document).on('click', '.delete-link', function () {
		$(this).parent().parent().remove();
	});

	// $(document).on('click', '.tab-url', function () {
		// window.onbeforeunload = '';
	// });

	//$('.select2').select2({ allowClear: true });

	$('#client_zipcode').on('change', function () {
		$.ajax({
			type: 'GET',
			url: '/geolocation/zip_code/' + $('#client_zipcode').val()
		}).done(function (response) {
			$('#client_locality').val(response.locality);
			$('#client_region').val(response.region);
			$('#client_country').val(response.country);
		});
	});

	$('#client_industry_id').select2({
		dropdownCssClass: 'bigdrop',
		placeholder: 'Select industry by NAICS industry code or by typing industry name',
		allowClear: true,
		ajax: {
			url: '/industries/tools/json_list',
			dataType: 'json',
			data: function (term, page) { return { id: $(this).val(), q: term } },
			results: function (data, page) { return { results: data } }
		},
		initSelection: function (item, callback) {
			var id = item.val();
			if (id !== '') {
				$.ajax('/industries/tools/json_list', {
					data: { id: id },
					dataType: 'json'
				}).done(function (data) {
					callback(data[0]);
				});
			}
		},
		formatResult: function (item) { return (item.text); },
		formatSelection: function (item) { return (item.text); },
		escapeMarkup: function (m) { return m; }
	}).on("click", function () {
    $(this).select2("open");
    var industry_id = $(this).val();
    if (industry_id != '') {
      $.ajax({
        type: 'GET',
        url: '/industries/' + industry_id + '.json',
        dataType: 'html',
        success: function (data) {
          var json_data = $.parseJSON(data);
          $('#industry_short_descriptions_count').text(json_data.short_descriptions_count);
          $('#industry_long_descriptions_count').text(json_data.long_descriptions_count);
          $('#industry_tags_count').text(json_data.tag_list_count);
          $('#industry_wordings_url').attr('href', '/wordings?resource_type=Industry&resource_id=' + industry_id);
          $('#industry_details').show();
        }
      });
    } else {
      $('#industry_details').hide();
    }
  });

	if (isForm('client', true, false)) {
		$('.new_client, .edit_client, .client-form').submit(function (e) {
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

  $(document).on('change', '.description-name-select', function () {
    text_input = $(this).closest('fieldset').find('textarea');
    text_input_limit = $('option:selected', $(this)).attr('data-text-type-limit');
    text_input_value = text_input.val();
    if (text_input_limit != undefined) {
      text_input.val(text_input_value.slice(0,text_input_limit));
      text_input.attr('maxlength', text_input_limit);
      text_input.attr('placeholder', 'Enter text (character limit: ' + text_input_limit + ')');
      text_input.trigger('change');
      if (text_input_value.length > text_input_limit){
        alert("Text string will be truncated!");
        text_input.effect('highlight', { color: 'red' }, 3000);
        text_input.trigger('keyup');
      }
    } else {
      text_input.val('');
      text_input.removeAttr('maxlength');
      text_input.attr('placeholder', 'Enter text');
      text_input.trigger('keyup');
    }
  });

	$(function () {
		if ($('#client_phones_csv').val() == '') $('#phones_add').trigger('click');
		collectPhones();
		phone_mask();
		$('.select2-container').addClass('form-control');

		$('#client_fax').inputmask();
		$('#client_protected_words').tagsinput();
	});
}

$(document).ready(ready);
$(document).on('page:load', ready);
