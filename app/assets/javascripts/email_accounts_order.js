$(function () {
	$('select').select2({ allowClear: true });

	$(document).ready(function () {
		window.onbeforeunload = function (evt) {
			message = 'Do you really want to leave this page? You may lost unsaved data!';
			if (typeof evt == 'undefined') evt = window.event;
			if (evt) evt.returnValue = message;
			return message;
		}

		$('.numeric').keypress(function (e) {
			if (e.which != 8 && e.which != 0 && (e.which < 48 || e.which > 57)) return false;
		});
	});

	$('#accounts_number').on('keypress', function (e) {
		if (event.keyCode == 13) $('#order').trigger('click');
	});

	$('#accounts_number').on('change', function () {
    var accounts_number_form_group = $('#accounts_number').closest('.form-group');
    accounts_number_form_group.attr('data-content', '');
    accounts_number_form_group.removeClass('has-error');
    accounts_number_form_group.popover('disable')
		var value = $('#accounts_number').val();
		if (value < 0) $('#accounts_number').val(0);
	});

	$('#order').on('click', function(){
		event.preventDefault();

		var choice = confirm('Are you sure?');

		if (choice) {
			window.onbeforeunload = '';
			if($('#accounts_number').val() > 0) {
				$('#order_email_accounts_form').submit();
			} else {
        var accounts_number_form_group = $('#accounts_number').closest('.form-group');
        accounts_number_form_group.attr('data-content', 'Introduce at least one account!');
        accounts_number_form_group.addClass('has-error');
        accounts_number_form_group.popover({
          trigger: 'hover',
          placement: 'bottom',
          animation: true
        });
        accounts_number_form_group.popover('enable');
			}
		}
	});
});
