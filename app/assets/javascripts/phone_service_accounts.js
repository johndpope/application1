$(function () {
    isForm('phone_service_account', true, true);

    $('select').select2({ allowClear: true });
    $('.select2-container').addClass('form-control');

		$(document).ready(function () {
			$('.numeric').keypress(function (e) {
				if (e.which != 8 && e.which != 0 && (e.which < 48 || e.which > 57)) return false;
			});
		});
});
