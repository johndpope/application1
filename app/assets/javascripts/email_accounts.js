//= require jquery-live-preview
//= require fancybox

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
			} else{
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

	regions_url = $('#regions_url').val()

	$('body').on('click', '*[data-legend-url]', function (event) {
		if (filter.hasClass('open')) {
			filter.css('right', 0);
			filter_settings.css('right', '-250px');
			filter.removeClass('open');
		}
		element = $(this);
		$('#email_account_legend').empty();
		$.ajax({ url: element.data('legend-url') }).done(function (response) {
			$('#email_account_legend').append(response).modal();
		});
	});

	$('select').select2({ allowClear: true });
	$('#country_id').on('change', function () {
		country_id = $(this).val();
		$('#region_id').attr('disabled', 'disabled').html('');
		$.ajax({
			type: 'GET',
			url: regions_url + '/' + country_id
		}).done(function (response) {
			$('#region_id').html(response);
			var selection = $('#s2id_region_id').find('.select2-chosen');
			selection.text('');
		}).fail(function (response) {}).always(function (e) {
			$('#region_id').removeAttr('disabled');
		});
	});

	$('#email_accounts_table th').on('click', function () {
		if ($(this).hasClass('sort')) {
			var data_field = $(this).attr('data-field');

			if ($(this).hasClass('sort_asc')) {
				$('#email_accounts_table th').removeClass('sort_asc').removeClass('sort_desc');
				$(this).removeClass('sort_asc').addClass('sort_desc');
				order_type.select2('val', 'desc');
			} else{
				$('#email_accounts_table th').removeClass('sort_asc').removeClass('sort_desc');
				$(this).removeClass('sort_desc').addClass('sort_asc');
				order_type.select2('val', 'asc');
			}
			order_by.select2('val', data_field);
			$('#filters_form').submit();
		}
	});

	// Edit functionality
	function submitForm (input) {
		var form = $('form');
		var valuesToSubmit = form.serialize();
		$.post(form.attr('action'), valuesToSubmit, 'json').success(function (response) {
			input.effect('highlight', { color: '#70CB6A' }, 2000);
		}).fail(function () {
			input.effect('highlight', { color: 'red' }, 3000);
		});
	}

	$('#edit_email_account input[type=text], #edit_email_account input[type=date], #edit_email_account textarea').on('change', function () {
		submitForm($(this));
	});

	$('#edit_email_account .iCheck-helper, #edit_email_account .checkbox-label').on('click', function () {
		submitForm($(this));
	});

	$('.best_in_place').bind('ajax:success', function (xhr, data, status) {
		$(this).effect('highlight', { color: '#70CB6A' }, 2000);
    $('#last_disabled_at_time').html(JSON.parse(data)['last_disabled_at']);
    $('#status_change_date_time').html(JSON.parse(data)['status_change_date']);
		$('#updated_at_time').html(JSON.parse(data)['updated_at']);
	});

	$('body').on('focus', '.best_in_place input[type=text]', function () {
		var element = this;
		setTimeout(function () { element.setSelectionRange(0, 0) }, 5);
	});

	$('.bip-checkbox').on('click', function () {
		var input = $(this);

		if (input.data("bip-value")) {
			if ($(this).hasClass('inverse')) {
				input.removeClass('btn-danger').addClass('btn-success');
			} else {
				input.removeClass('btn-success').addClass('btn-danger');
			}
		} else {
			if ($(this).hasClass('inverse')) {
				input.removeClass('btn-success').addClass('btn-danger');
			} else {
				input.removeClass('btn-danger').addClass('btn-success');
			}
		}
	});

	$(document).ready(function () {
    fancybox_settings = {
      helpers: {
        title : {
          type : 'float'
        }
      }
    }
    $(".image-preview").fancybox(fancybox_settings);

		jQuery('.best_in_place').best_in_place();

		$('.numeric').keypress(function (e) {
			 if (e.which != 13 && e.which != 8 && e.which != 0 && (e.which < 48 || e.which > 57)) return false;
		});

		$('.livepreview.left-livepreview').livePreview({
			position: 'left'
		});

		$('.livepreview').livePreview();

		$('span[data-bip-attribute="gender"]').text($('span[data-bip-attribute="gender"]').attr('data-bip-value'));

		makeASmallSitebar('auto');

    $('#show_screenshots_in_history').on('ifChanged', function (event) {
  		if (this.checked) {
  			$('.direct-chat-screenshot').show();
  		} else {
  			$('.direct-chat-screenshot').hide();
  		}
  	});
    $('#show_inbox_emails_in_history').on('ifChanged', function (event) {
  		if (this.checked) {
  			$('.direct-chat-inbox-email').show();
  		} else {
  			$('.direct-chat-inbox-email').hide();
  		}
  	});
    $('#show_recovery_responses_in_history').on('ifChanged', function (event) {
  		if (this.checked) {
  			$('.direct-chat-recovery-response').show();
  		} else {
  			$('.direct-chat-recovery-response').hide();
  		}
  	});
    $('#show_phone_usages_in_history').on('ifChanged', function (event) {
  		if (this.checked) {
  			$('.direct-chat-phone-usage').show();
  		} else {
  			$('.direct-chat-phone-usage').hide();
  		}
  	});

		$('#email_account_locality_id').select2({
			dropdownCssClass: 'bigdrop',
			minimumInputLength: 3,
			placeholder: 'Select location',
			allowClear: true,
			ajax: {
				url: '/localities',
					dataType: 'json',
					data: function (term, page) { return { q: term } },
					results: function (data, page) { return { results: data } }
				},
				initSelection: function (item, callback) {
					var id = item.val();
					if (id !== '') {
						$.ajax('/localities', {
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

		$('#email_account_region_id').select2({
			dropdownCssClass: 'bigdrop',
			minimumInputLength: 3,
			placeholder: 'Select region',
			allowClear: true,
			ajax: {
				url: '/all_regions',
				dataType: 'json',
				data: function (term, page) { return { q: term } },
				results: function (data, page) { return { results: data } }
			},
			initSelection: function (item, callback) {
				var id = item.val();

				if (id !== '') {
					$.ajax('/all_regions', {
						data: { id: id },
						dataType: 'json'
					}).done(function (data) {
						callback(data[0]);
					});
				}
			},
			formatResult: function (item) { return (item.text ); },
			formatSelection: function (item) { return (item.text); },
			escapeMarkup: function (m) { return m; }
		});

		$('#region_id').select2({
			dropdownCssClass: 'bigdrop',
			minimumInputLength: 3,
			placeholder: 'Select region',
			allowClear: true,
			ajax: {
				url: '/all_regions',
				dataType: 'json',
				data: function (term, page) { return { q: term } },
				results: function (data, page) { return { results: data } }
			},
			initSelection: function (item, callback) {
				var id = item.val();
				if (id !== '') {
					$.ajax('/all_regions', {
						data: { id: id },
						dataType: 'json'
					}).done(function (data) {
						callback(data[0]);
					});
				}
			},
			formatResult: function (item) { return (item.text ); },
			formatSelection: function (item) { return (item.text); },
			escapeMarkup: function (m) { return m; }
		});

		$('#locality_id').select2({
			dropdownCssClass: "bigdrop",
			minimumInputLength: 3,
			placeholder: 'Select locality',
			allowClear: true,
			ajax: {
				url: '/localities',
				dataType: 'json',
				data: function (term, page) { return { q: term } },
				results: function (data, page) { return { results: data } }
			},
			initSelection: function (item, callback) {
				var id = item.val();
				if (id !== '') {
					$.ajax('/localities', {
						data: {id: id},
						dataType: 'json'
					}).done(function (data) {
						callback(data[0]);
					});
				}
			},
			formatResult: function (item) { return (item.text ); },
			formatSelection: function (item) { return (item.text); },
			escapeMarkup: function (m) { return m; }
		});

		$('#email_account_locality_id').on('change', function () {
			var locality_block = $('#locality_block .select2-choice');
			submitForm(locality_block);
		});

		$('#email_account_region_id').on('change', function () {
			var region_block = $('#region_block .select2-choice');
			submitForm(region_block);
		});

		$('#email_account_account_type').on('change', function () {
			var account_type_block = $('#account_type_block .select2-choice');
			submitForm(account_type_block);
		});

		$('#email_account_email_item_attributes_google_status').on('change', function () {
			var google_status_block = $('#google_status_block .select2-choice');
			submitForm(google_status_block);
		});

		$('#email_account_email_item_attributes_account_category').on('change', function () {
			var account_category_block = $('#account_category_block .select2-choice');
			submitForm(account_category_block);
		});

		$('.activity-btn').click(function () {
			var item = $(this);
			var google_account_activity_id = $(this).data('id');
			var field_name = $(this).data('field');
			var parent = $(this).parent();

			$.ajax({
				type: 'GET',
				url: '/google_account_activities/' + google_account_activity_id + '/touch?field=' + field_name
			}).done(function (response) {
				parent.text(response.time);
				parent.effect('highlight', { color: '#70CB6A' }, 2000);
				setTimeout(function () {
					item.addClass('disabled');
				}, 1000);
			}).fail(function (response) {
				parent.effect('highlight', { color: 'red'}, 3000);
				console.log(response);
			});
		});
	});
});
