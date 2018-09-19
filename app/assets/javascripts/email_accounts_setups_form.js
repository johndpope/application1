$(function () {
	function clearMethod () {
		$('#cities_number_selection').hide();
		$('#population_greater_than_selection').hide();
		$('#states_selection').hide();
		$('#national_selection').hide();
		clearValues();
	}

	function clearValues () {
		$('#email_accounts_setup_top_cities_filter').val(0).trigger('change');
		$('#top_cities_select').val(0).trigger('change');
		$('#population_select').val(0).trigger('change');
		$('#email_accounts_setup_population_filter').val(0).trigger('change');
		$('#states_select').select2('val', '').trigger('change');
		clearStates();
		$('#clear_localities').trigger('click');
	}

	function clearStates() {
		if ($('#state_select_checkbox .icheckbox_minimal-blue').hasClass('checked')) {
			$('#state_select_checkbox ins').trigger('click');
		} else {
			$('#state_select_checkbox ins').trigger('click');
			$('#state_select_checkbox ins').trigger('click');
		}
	}

	$('select, .select2').select2();

	$(document).ready(function () {
		isForm('email_accounts_setup', true, true);

		$('#cities_list').on('change', function (event) {
			$('#email_accounts_setup_cities').val('{' + $('#cities_list').val() + '}');
			if ($('#cities_list').val() != '') {
				$('#badge_cities_current_count').text($('#cities_list').val().split(',').length);
        //$('#email_accounts_setup_accounts_number').val($('#cities_list').val().split(',').length);
        $('#check_localities_link').attr('href', '/artifacts/images/report_by_localities?locality_ids=' + $('#cities_list').val());
        $('#check_localities_block').show();
			} else {
				$('#badge_cities_current_count').text(0);
        $('#check_localities_block').hide();
        $('#check_localities_link').attr('href', '/artifacts/images/report_by_localities?locality_ids=');
			}
		});

		$('#counties_list').on('change', function (event) {
			$('#email_accounts_setup_counties').val('{' + $('#counties_list').val() + '}');
			if ($('#counties_list').val() != '') {
				$('#badge_counties_current_count').text($('#counties_list').val().split(',').length);
			} else {
				$('#badge_counties_current_count').text(0);
			}
		});

		$('#clear_localities').on('click', function () {
			$('#cities_list').select2('val', '');
			$('#cities_list').select2({
					placeholder: 'Select cities',
					minimumInputLength: 0,
					multiple: true,
					allowClear: true,
					data: function(){
							return {results: []}
					},
					initSelection: function(element, callback){
					}
			});
			$('#cities_json').val('');
			$('#email_accounts_setup_cities').val('{}');
			$('#counties_list').select2('val', '');
			$('#counties_list').select2({
					placeholder: 'Select counties',
					minimumInputLength: 0,
					multiple: true,
					allowClear: true,
					data: function(){
							return {results: []}
					},
					initSelection: function(element, callback){
					}
			});
			$('#counties_json').val('');
			$('#email_accounts_setup_counties').val('{}');
			$('#badge_cities_count').text(0);
			$('#badge_cities_current_count').text(0);
			$('#badge_counties_count').text(0);
			$('#badge_counties_current_count').text(0);
      $('#check_localities_block').hide();
      $('#check_localities_link').attr('href', '/artifacts/images/report_by_localities?locality_ids=');
		});

		$('#select_all_localities').on('click', function(){
			$('#cities_list').select2('val', 'All');
			$('#cities_list').trigger('change');
			$('#counties_list').select2('val', 'All');
			$('#counties_list').trigger('change');
		});

		function searchLocalities() {
			$('.animationload').show();
			if ($('#locality_cities_radio').parent().attr('aria-checked') == 'true' || $('#locality_cities_radio').parent().hasClass('checked')) {
        if ($('#email_accounts_setup_states').val() != '' && $('#email_accounts_setup_states').val() != null) {
          var url = '/cities?population=' + $('#email_accounts_setup_population_filter').val()
  					+ '&country=' + $('#email_accounts_setup_country_id').val() + '&states=' + $('#email_accounts_setup_states').val()
  					+ '&ids=' + $('#email_accounts_setup_cities').val().replace('{', '').replace('}', '');

  				$.ajax({
  					type: 'POST',
  					url: url
  				}).done(function (response) {
  					console.log(response);
  					data_array = [];
  					for (var i = 0, reLg = response.length; i < reLg; i++) {
  						data_array.push({ id: response[i].id, text: response[i].text })
  					}
  					$('#cities_list').select2({
  			        placeholder: 'Select cities',
  			        minimumInputLength: 0,
  			        multiple: true,
  			        allowClear: true,
  			        data: function(){
  			            return {results: data_array}
  			        },
  			        initSelection: function(element, callback){
  			          callback(data_array);
  			        }
  			    });
  					$('#email_accounts_setup_cities').val('{' + $('#cities_list').val() + '}');
  					$('#badge_cities_count').text(response.length);
  					$('.animationload').hide();
  				}).fail(function (response) {
  					$('.animationload').hide();
  					console.log(response);
  				});
        } else {
          $('.animationload').hide();
          alert("Select at least one state/region");
        }
			} else {
				var url = '/counties?population=' + $('#email_accounts_setup_population_filter').val()
					+ '&country=' + $('#email_accounts_setup_country_id').val() + '&states=' + $('#email_accounts_setup_states').val()
					+ '&ids=' + $('#email_accounts_setup_counties').val().replace('{', '').replace('}', '');

				$.ajax({
					type: 'POST',
					url: url
				}).done(function (response) {
					data_array = []
					for (var i = 0, reLg = response.length; i < reLg; i++) {
						data_array.push({ id: response[i].id, text: response[i].text })
					}
					$('#counties_list').select2({
							placeholder: 'Select counties',
							minimumInputLength: 0,
							multiple: true,
							allowClear: true,
							data: function(){
									return {results: data_array}
							},
							initSelection: function(element, callback){
								callback(data_array);
							}
					});
					$('#email_accounts_setup_counties').val('{' + $('#counties_list').val() + '}');
					$('#badge_counties_count').text(response.length);
					$('.animationload').hide();
				}).fail(function (response) {
					$('.animationload').hide();
					console.log(response);
				});
			}
		}

		$('#search_localities').on('click', function () {
			$('#clear_localities').trigger('click');
			searchLocalities();
		});

		$('#counties_select_block input, #cities_select_block input').keypress(function (e) {
			return false;
		});

		$('.numeric').keypress(function (e) {
			if (e.which != 8 && e.which != 0 && (e.which < 48 || e.which > 57)) return false;
		});

		$('#packages_radio_group div.radio label, #packages_radio_group div.radio ins').on('click', function () {
			clearMethod();

			if ($('#top_cities_radio').parent().attr('aria-checked') == 'true') $('#cities_number_selection').show();

			if ($('#population_greater_than_radio').parent().attr('aria-checked') == 'true') $('#population_greater_than_selection').show();

			if ($('#states_radio').parent().attr('aria-checked') == 'true') $('#states_selection').show();

			if ($('#national_radio').parent().attr('aria-checked') == 'true') {
				$('#population_greater_than_selection').show();
				$('#national_selection').show();
			}

			if ($('#regional_radio').parent().attr('aria-checked') == 'true') {
				$('#population_greater_than_selection').show();
				$('#states_selection').show();
				$('#national_selection').show();
			}

			var package_choice;

			if ($(this).hasClass('iCheck-helper')) {
				package_choice = $(this).parent().find('input').val();
			} else {
				package_choice = $(this).find('input').val();
			}

			$('#email_accounts_setup_package').val(package_choice);
		});

		function clearLocalitiesRadioGroup() {
			$('#clear_localities').trigger('click');
			$('#cities_select_block').hide();
			$('#counties_select_block').hide();
		}

		$('#localities_radio_group div.radio label, #localities_radio_group div.radio ins').on('click', function () {
			clearLocalitiesRadioGroup();
			if ($('#locality_cities_radio').parent().attr('aria-checked') == 'true' || $('#locality_cities_radio').parent().hasClass('checked')) $('#cities_select_block').show();
			if ($('#locality_counties_radio').parent().attr('aria-checked') == 'true' || $('#locality_counties_radio').parent().hasClass('checked')) $('#counties_select_block').show();
		});

		$('#email_accounts_setup_channels_per_account').on('change', function () {
			var value = $('#email_accounts_setup_channels_per_account').val();

			if (value > 1) {
				$('#channels_reason_block').show();
			} else {
				$('#channels_reason_block').hide();
			}

			if (value < 1) $('#email_accounts_setup_channels_per_account').val(1);
		});

		$('#email_accounts_setup_accounts_number').on('change', function () {
			var value = $('#email_accounts_setup_accounts_number').val();

			if (value < 1) $('#email_accounts_setup_accounts_number').val('');
		});

		$('#email_accounts_setup_gplus_business_pages_per_account').on('change', function () {
			var value = $('#email_accounts_setup_gplus_business_pages_per_account').val();

			if (value > 1) {
				$('#google_plus_reason_block').show();
			} else {
				$('#google_plus_reason_block').hide();
			}

			if (value < 1) $('#email_accounts_setup_gplus_business_pages_per_account').val(1);
		});

		$('#google_plus_div ins, #google_plus_div label').on('click', function () {
			if ($('#google_plus_div .icheckbox_minimal-blue').hasClass('checked')) {
				$('#email_accounts_setup_gplus_business_pages_per_account').val(1);
				var value = $('#email_accounts_setup_gplus_business_pages_per_account').val();
				$('#googl_plus_pages_block').show();

				if (value > 1) {
					$('#google_plus_reason_block').show();
				} else {
					$('#google_plus_reason_block').hide();
				}
			} else {
				$('#email_accounts_setup_gplus_business_pages_per_account').val(0);
				$('#email_accounts_setup_additional_business_pages_reason').val('');
				$('#googl_plus_pages_block').hide();
				$('#google_plus_reason_block').hide();
			}
		});

		$('#state_select_checkbox ins, #state_select_checkbox label').click(function () {
			if ($('#state_select_checkbox .icheckbox_minimal-blue').hasClass('checked')) {
				$('#email_accounts_setup_states > option').prop('selected', 'selected');
				$('#email_accounts_setup_states').trigger('change');
			} else{
				$('#email_accounts_setup_states > option').removeAttr('selected');
				$('#email_accounts_setup_states').trigger('change');
			}
		});

    // $('#email_accounts_setup_states').on('change', function (){
    //   $(this).closest('.form-group').find('.calc-one').text($('#email_accounts_setup_states option:selected').length);
    // });

    function calc_states() {
      $('#email_accounts_setup_states').closest('.form-group').find('.calc-one').text($('#email_accounts_setup_states option:selected').length);
    }

    calc_states();

    $(document).on('change', '#email_accounts_setup_states', function () {
      calc_states();
    });

		if ($('#national_radio').parent().hasClass('checked') || $('#regional_radio').parent().hasClass('checked')) {
			var response;

			if ($('#cities_json').val() != '') {
				response = JSON.parse($('#cities_json').val());

				data_array = []
				for (var i = 0, reLg = response.length; i < reLg; i++) {
					data_array.push({ id: response[i].id, text: response[i].text })
				}
				$('#cities_list').select2({
						placeholder: 'Select cities',
						minimumInputLength: 0,
						multiple: true,
						allowClear: true,
						data: function(){
							return {results: data_array}
						},
						initSelection: function(element, callback){
							callback(data_array);
						}
				});
				$('#cities_list').select2("val", data_array);
				$('#cities_list').trigger('change');
			}

			if ($('#counties_json').val() != '') {
				response = jQuery.parseJSON($('#counties_json').val());

				data_array = []
				for (var i = 0, reLg = response.length; i < reLg; i++) {
					data_array.push({ id: response[i].id, text: response[i].text })
				}
				$('#counties_list').select2({
						placeholder: 'Select counties',
						minimumInputLength: 0,
						multiple: true,
						allowClear: true,
						data: function(){
								return {results: data_array}
						},
						initSelection: function(element, callback){
							callback(data_array);
						}
				});
				$('#counties_list').select2("val", data_array);
				$('#counties_list').trigger('change');
			}
		}
	});

	$('#top_cities_select').on('change', function () {
		$('#email_accounts_setup_top_cities_filter').val($(this).val()).trigger('change');
	});

	$('#population_select').on('change', function () {
		$('#email_accounts_setup_population_filter').val($(this).val()).trigger('change');
	});

	$('#top_cities_btn').on('click', function () {
		if ($('#s2id_top_cities_select').is(':visible')) {
			$(this).text('Choose from the list');
			$('#email_accounts_setup_top_cities_filter').show();
			$('#s2id_top_cities_select').hide();
		} else {
			$(this).text('Enter your value');
			$('#top_cities_select').val(0).trigger('change');
			$('#email_accounts_setup_top_cities_filter').hide();
			$('#s2id_top_cities_select').show();
		}
	});

	$('#population_btn').on('click', function () {
		if ($('#s2id_population_select').is(':visible')) {
			$(this).text('Choose from the list');
			$('#email_accounts_setup_population_filter').show();
			$('#s2id_population_select').hide();
		} else {
			$(this).text('Enter your value');
			$('#population_select').val(0).trigger('change');
			$('#email_accounts_setup_population_filter').hide();
			$('#s2id_population_select').show();
		}
	});

	$('#email_accounts_setup_top_cities_filter').on('change', function () {
		var top_cities_filter = $(this).val();

		if (top_cities_filter == '' || top_cities_filter < 1) {
			$(this).val(0);
			$('#email_accounts_setup_cities').val('');
		} else {
      $('.animationload').show();
			$.ajax({
				type: 'POST',
				url: '/localities/top/' + top_cities_filter + '?country=' + $('#email_accounts_setup_country_id').val()
			}).done(function (response) {
				var insert = [];

				for (var i = 0, reLg = response.length; i < reLg; i++) {
					insert.push(response[i].id);
				}

				$('#email_accounts_setup_cities').val('{' + insert + '}');
        $('.animationload').hide();
			}).fail(function (response) {
        $('.animationload').hide();
				console.log(response);
			});
		}
	});

	$('#email_accounts_setup_population_filter').on('change', function () {
		var population_filter = $(this).val();

		if (population_filter == '' || population_filter < 1) {
			$(this).val(0);
			$('#email_accounts_setup_cities').val('');
		} else {
			if ($('#population_greater_than_radio').parent().attr('aria-checked') == 'true' || $('#population_greater_than_radio').parent().hasClass('checked')) {
        $('.animationload').show();
				$.ajax({
					type: 'POST',
					url: '/localities/population_greater/' + population_filter + '?country=' + $('#email_accounts_setup_country_id').val()
				}).done(function (response) {
					var insert = [];

					for (var i = 0, reLg = response.length; i < reLg; i++) {
						insert.push(response[i].id);
					}

					$('#email_accounts_setup_cities').val('{' + insert + '}');
          $('.animationload').hide();
				}).fail(function (response) {
          $('.animationload').hide();
					console.log(response);
				});
			}
		}
	});

	$('#email_accounts_setup_country_id').on('change', function () {
		clearValues();
		$('#email_accounts_setup_states').children().remove();
		var url = '/states?country=' + $('#email_accounts_setup_country_id').val();

		$.ajax({
			type: 'GET',
			url: url
		}).done(function (response) {
			var insert = '';

			for (var i = 0, reLg = response.length; i < reLg; i++) {
				insert += '<option value="' + response[i].id + '">' + response[i].text + '</option>';
			}

			$('#email_accounts_setup_states').html(insert);
		}).fail(function (response) {
			console.log(response);
		});
	});
});
