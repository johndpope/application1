//= require jquery
//= require jquery.ui.all
$(function () {
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
				localStorage.setItem('email-accounts-filter-settings-open', 'true');
			} else {
				localStorage.setItem('email-accounts-filter-settings-open', 'false');
			}
		} else {
			console.log('Sorry, your browser does not support Web Storage...');
		}
	});

	if (typeof(Storage) != 'undefined' && localStorage.getItem('email-accounts-filter-settings-open') == 'true') {
    filter.animate({ 'right': '250px' });
    filter_settings.animate({ 'right': '0' });
    filter.addClass("open");
	}

	$('#list_of_contact_us th').on('click', function () {
		if ((e = $(this)).hasClass('sort')) {
			var data_field = e.attr('data-field');

			if (e.hasClass('sort_asc')) {
				$('#list_of_contact_us th').removeClass('sort_asc').removeClass('sort_desc');
				e.removeClass('sort_asc').addClass('sort_desc');
				order_type.select2('val', 'desc');
			} else {
				$('#list_of_contact_us th').removeClass('sort_asc').removeClass('sort_desc');
				e.removeClass('sort_desc').addClass('sort_asc');
				order_type.select2('val', 'asc');
			}

			order_by.select2('val', data_field);
			$('#filters_form').submit();
		}
	});

});
