$(function () {
    isForm('api_account', true, true);

    $('select').select2({ allowClear: true });
    $('.select2-container').addClass('form-control');

		$(document).ready(function () {
			$('.numeric').keypress(function (e) {
				if (e.which != 8 && e.which != 0 && (e.which < 48 || e.which > 57)) return false;
			});
		});
});

$(function () {
	isForm('api_account', true, true);

	$('select').select2({ allowClear: true });
	$('.select2-container').addClass('form-control');

	$('body').on('click', '*[data-legend-url]', function (event) {
		element = $(this);
		$('#api_account_legend').empty();
		$.ajax({ url: element.data('legend-url') }).done(function (response) {
			$('#api_account_legend').append(response).modal();
		});
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
				localStorage.setItem('api-accounts-filter-settings-open', 'true');
			} else {
				localStorage.setItem('api-accounts-filter-settings-open', 'false');
			}
		} else {
			console.log('Sorry, your browser does not support Web Storage...');
		}
	});

	if (typeof(Storage) != 'undefined' && localStorage.getItem('api-accounts-filter-settings-open') == 'true') {
    filter.animate({ 'right': '250px' });
    filter_settings.animate({ 'right': '0' });
    filter.addClass("open");
	}

	$('#api_accounts_table th').on('click', function () {
		if ($(this).hasClass('sort')) {
			var data_field = $(this).attr('data-field');
			if ($(this).hasClass('sort_asc')) {
				$('#api_accounts_table th').removeClass('sort_asc').removeClass('sort_desc');
				$(this).removeClass('sort_asc').addClass('sort_desc');
				order_type.select2('val', 'desc');
			} else {
				$('#api_accounts_table th').removeClass('sort_asc').removeClass('sort_desc');
				$(this).removeClass('sort_desc').addClass('sort_asc');
				order_type.select2('val', 'asc');
			}
			order_by.select2('val', data_field);
			$('#filters_form').submit();
		}
	});
});
