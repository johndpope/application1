//= require jquery-live-preview

var ready = function () {
	if (isForm('client_landing_page', true, true)) {
    countKeywords();
    var location_arr = window.location.href.split("/");

    var colorizerOptions = {
      // Editor options
       width: 960,
       // Colorizer editor width in pixels, min width 640
       // (the palette editor is 420px wide, the rest is for preview)
       height: 500,
       // Colorizer height in pixels, min. height 500
       dark: false,
       // the Colorizer UI style: false = white Colorizer UI, true = dark Colorizer UI
       // Preview template
       templateURL: location_arr[0] + "//" + location_arr[2] + '/paletton/index.html',
       // the URL of your preview HTML document.
       // A full URL must be provided, i.e. 'http://example.org/templates/template-01/index.html'
       paletteUID: '1000u0kllllaFw0g0qFqFg0w0aF',
       // the UID of init palette as provided by the Paletton.com application
       paletteUIDdefault: '1000u0kllllaFw0g0qFqFg0w0aF',
       // the UID of default palette to be used for reset action. If omitted, the init value is used instead.
       colorizeMode: 'class',
       // the colorize mode (see above), possible values = "class" | "less" | "custom"
       // Various
       myData: null
    }

    var link = document.getElementById('colorize-button');

    link.onclick = function(e){
       e.preventDefault();
       _paletton.open(colorizerOptions, colorizerCallback);
    }

    /* Your custom callback */
    /* This one just gets the Colorizer data and dumps them into the page as a readable text */
    function colorizerCallback(data){
      // data = { colorTable, paletteUID, myData }
      // your code here
      if (!data) {
        return
      }

      colorizerOptions.paletteUID = data.paletteUID;
      /* storing the palette for next time */

      function parse(obj,prefix) {
        // a dummy recursive parser just to print out the data
        var k, x, str = '{\n';
          for (k in obj) {
            x = obj[k];
            str += prefix + '   ' + k + ': ';
            if (typeof x==='undefined' || x===null) str += 'null';
            else if (typeof x==='object') str += parse(x, prefix + '   ');
            else str += x;
            str += '\n';
          }
          str += prefix + '   ' + '}';
          return str;
        }
        console.log(parse(data, ''))
    } // callback
  } else {
    //index page code
  }

	$('select').select2({ allowClear: true });

  var order_by = $('#filter_order');
  var order_type = $('#filter_order_type');
  var th = $('#' + order_by.val() + '-th');

  if(th !== 'undefined') th.addClass('sort_' + order_type.val());

  var filter = $('#filter');
  var filter_settings = $('#filter_settings');

  filter.click(function() {
    var open = false;
    if (!$(this).hasClass("open")) {
      $(this).animate({ 'right': '250px' });
      filter_settings.animate({ 'right': '0' });
      $(this).addClass("open");
      open = true;
    } else {
      $(this).animate({ 'right': '0' });
      filter_settings.animate({ 'right': '-250px' });
      $(this).removeClass("open");
    }

    if (typeof(Storage) != "undefined") {
      if (open) {
        localStorage.setItem("email-accounts-filter-settings-open", "true");
      } else {
        localStorage.setItem("email-accounts-filter-settings-open", "false");
      }
    } else {
      console.log("Sorry, your browser does not support Web Storage...");
    }
  });

  if (typeof(Storage) != "undefined" && localStorage.getItem("email-accounts-filter-settings-open") == "true") {
    filter.animate({ 'right': '250px' });
    filter_settings.animate({ 'right': '0' });
    filter.addClass("open");
  }

  $("#client_landing_pages_table th").on("click", function() {
    if($(this).hasClass("sort")) {
      var data_field = $(this).attr("data-field");

      if ($(this).hasClass("sort_asc")) {
          $("#recovery_attempt_responses_table th").removeClass("sort_asc").removeClass("sort_desc");
          $(this).removeClass("sort_asc").addClass("sort_desc");
          order_type.select2("val", "desc");
      } else {
          $("#recovery_attempt_responses_table th").removeClass("sort_asc").removeClass("sort_desc");
          $(this).removeClass("sort_desc").addClass("sort_asc");
          order_type.select2("val", "asc");
      }

      order_by.select2("val", data_field);
      $("#filters_form").submit();
    }
  });

  $('.livepreview.left-livepreview').livePreview({
    position: 'left'
  });

  $('.livepreview').livePreview();

	$('#client_landing_page_client_landing_page_template_id').on('select2-highlight', function (e) {
		get_tamplate(e.choice.id);
	}).on('select2-close', function () {
		get_tamplate($('#client_landing_page_client_landing_page_template_id').val());
	}).select2({ allowClear: false });

  $('#use_client_logo').on('click', function(){
    $.ajax({
      url: '/clients/' + $('#client_landing_page_client_id').val() + '.json',
      dataType: 'json',
      success: function(data) {
        if (data.logo_url != '') {
          $('#client_landing_page_logo_image_url').val(data.logo_url);
          $('#client_landing_page_logo_image_url').effect('highlight', { color: '#4caf50' }, 2000)
        } else {
          alert("You didn't upload client logo!");
        }
      },
  		error: function (data) {
  			console.log(data);
  		}
    });
  });

	$('#bs_add').click(function () {
		$('#body_sections .body-section:first').clone().insertBefore('#body_sections .bs-footer');

		p = $('.body-section:last');
		p.find('.remove-fields').addClass('dib');
		p.find('input, textarea').val('').prop("disabled", false);
    p.find('input[type=checkbox]').each(function (index, element) {
      if ($(element).checked) {
        $(element).trigger('click');
      }
      $(element).removeAttr('checked');
      $(element).val("false");
    });

		renameIndex();
	});

	$(document).on('click', '.remove-fields', function () {
		if (confirm('Are you sure you want to remove this entry?')) {
			$(this).closest('.body-section').remove();
			renameIndex();
		} else {
			return false;
		}
	});

  $(document).on('click', '.form-group label', function (event) {
    $(event.target).prev().trigger("click");
	});

  $(document).on('click', 'input[type=checkbox]', function (event) {
    $(event.currentTarget).val(event.currentTarget.checked);
  });

	$(document).on('change', '.video-url-input', function (event) {
		if( $(event.target).val().length === 0 ) {
			$(event.target).parent().find('.image-url-input').first().prop("disabled", false);
	  } else {
			$(event.target).parent().find('.image-url-input').first().prop("disabled", true).val('');
		}
	});

	$(document).on('change', '.image-url-input', function (event) {
		if( $(event.target).val().length === 0 ) {
		  $(event.target).parent().find('.video-url-input').first().prop("disabled", false);
	  } else {
			$(event.target).parent().find('.video-url-input').first().prop("disabled", true).val('');
		}
	});

	$(function () {
		$('#body_sections').sortable({
			items: '.body-section',
			axis: 'y',
			handle: 'legend',
			revert: true,
			start: function (event, ui) {
				$(ui.item.context).find('fieldset').addClass('drag');
			},
			stop: function (event, ui) {
				renameIndex();
				$(ui.item.context).find('fieldset').removeClass('drag');
			}
		});
	});
}

$(document).ready(ready);
$(document).on('page:load', ready);

function renameIndex () {
	$('.body-section').each(function (index, element) {
		rf = $(this).find('.remove-fields');
		(index == 0) ? rf.removeClass('dib') : rf.addClass('dib');

		$(element).find('input, textarea').each(function (i, e) {
			el = $(e);
			el.attr('name', 'client_landing_page[body_sections][' + index + '][' + el.attr('data-name') + ']');
		});
	});
}

function countKeywords(){
  keywords_count = 0;
  var keywords = $("#client_landing_page_meta_keywords").val();
  if (keywords != '') {
    var keywords_array = keywords.split(",").filter(Boolean);
    keywords_count = keywords_array.length;
  }
  $("#keywords_label").text(keywords_count);
}

$(document).on('keyup', '#client_landing_page_meta_keywords', function () {
  countKeywords();
});

function get_tamplate (id) {
	$.ajax({
		url: '/client_landing_pages/get_tamplate',
		type: 'POST',
		dataType: 'json',
		data: { id: id },
		success: function (data) {
			$('#template_preview > a').attr('href', data.original).attr('data-src', data.original);
			$('#template_preview > a > img').attr('src', data.thumb);
		},
		error: function (data) {
			console.log(data);
		}
	});
}
