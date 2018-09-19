//= require jquery
//= require jquery.ui.all

var ready = function () {
	$('select').select2({ allowClear: true });
	$('.select2-container').addClass('form-control');

	$('a.showInModal[data-id]').click(function () {
		id = $(this).attr('data-id');

		$.ajax({
			url: '/sandbox/contact_us/show',
			data: { 'id': id },
			type: 'post',
			success: function (data) {
				$('#showMail .modal-body').html(data);
				$('#showMail').modal('show');
			}
		});
	});

	$('#showMail').on('hidden.bs.modal', function () {
		$('#showMail .modal-body').html('');
	});

	$(document).on('click', '#mark_as_read', function () {
		e = $(this);
		status = e.attr('data-status');

		$.ajax({
			url: '/sandbox/contact_us/read',
			data: {
				'id': id,
				'status': status
			},
			type: 'post',
			success: function (data) {
				if (data == 'true') {
					e.removeClass('btn-primary').addClass('btn-default').attr('data-status', 'false');
					$('a.showInModal[data-id="' + id + '"]').closest('tr').removeClass('active');
					e.html('<i class="glyphicon glyphicon-remove mr"></i> Mark as unread');
				} else {
					e.removeClass('btn-default').addClass('btn-primary').attr('data-status', 'true');
					$('a.showInModal[data-id="' + id + '"]').closest('tr').addClass('active');
					e.html('<i class="glyphicon glyphicon-ok mr"></i> Mark as read');
				}
			},
			error: function (data) {
				console.log(data);
			}
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
}

$(document).ready(ready);
$(document).on('page:load', ready);
