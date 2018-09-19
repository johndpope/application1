$(function () {
    isForm('phone_service_account', true, true);

		$('#regions_select').select2();

    $('select').select2({ allowClear: true });
    $('.select2-container').addClass('form-control');

		$('#dids_number').on('change', function () {
			var value = $('#dids_number').val();
			if (value < 1) $('#dids_number').val(1);
		});

		$(document).ready(function () {
			$('.numeric').keypress(function (e) {
				if (e.which != 8 && e.which != 0 && (e.which < 48 || e.which > 57)) return false;
			});

			$('#state_select_checkbox ins, #state_select_checkbox label').click(function () {
				if ($('#state_select_checkbox .icheckbox_minimal-blue').hasClass('checked')) {
					$('#regions_select > option').prop('selected', 'selected');
					$('#regions_select').trigger('change');
				} else{
					$('#regions_select > option').removeAttr('selected');
					$('#regions_select').trigger('change');
				}
			});

			$('input[type="radio"][name="optionsRadios"]').on('ifChecked', function (event) {
				$('.animationload').show();
				$('#regions_select').select2('val', '');
				$('#state_select_all').iCheck('uncheck');
				value = $(this).val();

				if (value != 'INT') {
					$('#country_select').select2('val', value);

					$.get('/phone_service_accounts/' + $('#phone_service_account_id').val() + '/voipms_regions',
						{ country_code: $('#country_select').val() },
						onAjaxSuccess
					);

					function onAjaxSuccess (data) {
						var tmp = '';

						for (var key in data) {
							if (data.hasOwnProperty(key)) tmp += '<option value="' + data[key] + '">' + key + '</option>"';
						}

						$('#regions_select').html('').html(tmp);
						$('.animationload').hide();
					}
				}
			});

			$('form.edit_phone_service_account').submit(function (e) {
				if (!$('#regions_select').val()) {
					e.preventDefault();
					alert('Select at least one state/region');
				} else {
					var country_code = $('#country_select').val();
					var perminute_monthly_price_limit = 0;
					var flat_setup_price_limit = 0;
					if (country_code == 'CA') {
						perminute_monthly_price_limit = $('#perminute_monthly_price_can_limit').val();
						flat_setup_price_limit = $('#flat_setup_price_can_limit').val();
					} else {
						if (country_code == "US") {
							perminute_monthly_price_limit = $('#perminute_monthly_price_usa_limit').val();
							flat_setup_price_limit = $('#flat_setup_price_usa_limit').val();
						} else {
							//international
							perminute_monthly_price_limit = $('#perminute_monthly_price_int_limit').val();
							flat_setup_price_limit = $('#flat_setup_price_int_limit').val();
						}
					}
					var total = parseFloat($('#dids_number').val()) * (parseFloat(perminute_monthly_price_limit) + parseFloat(flat_setup_price_limit));
					var balance = parseFloat($('#balance').val());
					console.log(total);
					console.log(balance);
					if (total > balance){
						e.preventDefault();
						alert('Your balance is too low: $' + balance + '. Your order: $' + total);
					}
				}
			});
		});
});
