var ready = function () {
  $('#industry_package').select2({allowClear: true});
	$('#client_business_type').select2({allowClear: true});
	$('#filter_settings select').select2({ allowClear: true });
  $('#filter_settings .select2-container').addClass('form-control');
  $('.bot-server').select2({ allowClear: true });
  $('.bot-server .select2-container').addClass('form-control');

  $('#industry_package').on('change', function(){
    $('#new_client_button').attr('href', '/clients/new?industry_id=' + $(this).val());
  });

  $('#industry_id').select2({
    dropdownCssClass: 'bigdrop',
    placeholder: 'Select industry',
    allowClear: true,
    ajax: {
      url: '/industries/tools/json_list',
      dataType: 'json',
      data: function (term, page) { return { q: term } },
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
  });

	var order_by = $('#filter_order');
	var order_type = $('#filter_order_type');
	var th = $('#' + order_by.val() + '-th');

	if (th !== 'undefined') th.addClass('sort_' + order_type.val());

	var filter = $('#filter');
	var filter_settings = $('#filter_settings');

	filter.click(function () {
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

		if (typeof(Storage) != 'undefined') {
			if (open) {
				localStorage.setItem('clients-filter-settings-open', 'true');
			} else {
				localStorage.setItem('clients-filter-settings-open', 'false');
			}
		} else {
			console.log('Sorry, your browser does not support Web Storage...');
		}
	});

	if (typeof(Storage) != 'undefined' && localStorage.getItem('clients-filter-settings-open') == 'true') {
    filter.animate({ 'right': '250px' });
    filter_settings.animate({ 'right': '0' });
    filter.addClass("open");
	}

	$('#clients_table th').on('click', function () {
		if ($(this).hasClass('sort')) {
			var data_field = $(this).attr('data-field');
			if ($(this).hasClass('sort_asc')) {
				$('#clients_table th').removeClass('sort_asc').removeClass('sort_desc');
				$(this).removeClass('sort_asc').addClass('sort_desc');
				order_type.select2('val', 'desc');
			} else {
				$('#clients_table th').removeClass('sort_asc').removeClass('sort_desc');
				$(this).removeClass('sort_desc').addClass('sort_asc');
				order_type.select2('val', 'asc');
			}
			order_by.select2('val', data_field);
			$('#filters_form').submit();
		}
	});

  $('.bot-server').on('change', function(){
    var client_id = $(this).parent().parent().attr("id").replace("tr_cl_","");
    var bot_server_td = $('#tr_cl_' + client_id + ' .bot-server').parent();
    var select_element = $('#tr_cl_' + client_id + ' #bot_server_id');
    var bot_server_id = select_element.val();
    var r = confirm("Are you sure?");
    if (r == true) {
      select_element.attr("data-selected-value", select_element.val());
      $.ajax('/clients/' + client_id + '/assign_accounts_to_bot_server?bot_server_id=' + bot_server_id, {
        dataType: 'json'
      }).success(function () {
        bot_server_td.effect('highlight', { color: 'green' }, 5000);
  		}).fail(function () {
  			bot_server_td.effect('highlight', { color: 'red' }, 5000);
  		});
    } else {
      select_element.select2("val", select_element.attr("data-selected-value"));
    }
  });

	$(function () {
	  $('[data-toggle="popover"]').popover()
	})


  $('.check_product_videos').on('change', function(){
    checked = $(this).prop("checked")
    console.log(checked)
    $(':checkbox.check_product_video', $(this).closest('.panel-body')).prop('checked', checked);
	});

  $('body').on('click', '*[data-legend-url]', function (event) {
		if (filter.hasClass('open')) {
			filter.css('right', 0);
			filter_settings.css('right', '-250px');
			filter.removeClass('open');
		}
		element = $(this);
		$('#client_legend').empty();
		$.ajax({ url: element.data('legend-url') }).done(function (response) {
			$('#client_legend').append(response).modal();
		});
	});
}

$(document).ready(ready);
$(document).on('page:load', ready);
