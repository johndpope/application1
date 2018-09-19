function ucfirst (str) {
	first = str.substr(0, 1).toUpperCase();
	return first + str.substr(1);
}

$(function () {
	function insert_resource (id, type) {
		$('#resource_id').val(id);
		$('#resource_type').select2('val', type);
	}

	$('body').on('click', '*[data-legend-url]', function (event) {
		element = $(this);
		$('#wording_legend').empty();
		$.ajax({ url: element.data('legend-url') }).done(function (response) {
			$('#wording_legend').append(response).modal();
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

	$('#wordings_table th').on('click', function () {
		if ($(this).hasClass('sort')) {
			var data_field = $(this).attr('data-field');

			if ($(this).hasClass('sort_asc')) {
				$('#wordings_table th').removeClass('sort_asc').removeClass('sort_desc');
				$(this).removeClass('sort_asc').addClass('sort_desc');
				order_type.select2('val', 'desc');
			} else {
				$('#wordings_table th').removeClass('sort_asc').removeClass('sort_desc');
				$(this).removeClass('sort_desc').addClass('sort_asc');
				order_type.select2('val', 'asc');
			}
			order_by.select2('val', data_field);
			$('#filters_form').submit();
		}
	});

  $('#industry_id').select2({
		dropdownCssClass: 'bigdrop',
		placeholder: 'NAICS industry code or name',
		allowClear: true,
		ajax: {
			url: '/industries/tools/json_list',
			dataType: 'json',
			data: function (term, page) { return { id: $(this).val(), q: term } },
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
	}).on("click", function () {
    $(this).select2("open");
  });

	$(document).on('change', '#industry_id', function () {
		insert_resource($(this).val(), 'Industry');
	});

	$(document).on('change', '.change-select', function () {
		el = $(this);
		id = el.val();
		type_from_id = ucfirst(el.attr('id').replace('_id', ''));

		if (type_from_id == 'State' || type_from_id == 'County') {
			type = 'Geobase::Region';
		} else {
			type = (id) ? 'Geobase::' + type_from_id : '';
		}

		insert_resource(id, type);

		params = { filter: type_from_id }

		if (type_from_id == 'Country') {
			params.country_id = $('#country_id').val();
			delete params.state_id
			delete params.locality_id
			delete params.landmark_id
		} else if (type_from_id == 'State') {
			params.country_id = $('#country_id').val();
			params.state_id = $('#state_id').val();
			delete params.locality_id
			delete params.landmark_id
		} else if (type_from_id == 'Locality') {
			params.country_id = $('#country_id').val();
			params.state_id = $('#state_id').val();
			params.locality_id = $('#locality_id').val();
			delete params.landmark_id
		} else if (type_from_id == 'Landmark') {
			params.country_id = $('#country_id').val();
			params.state_id = $('#state_id').val();
			params.locality_id = $('#locality_id').val();
			params.landmark_id = $('#landmark_id').val();
		}

		if (type_from_id != 'County') {
			$.ajax({
				url: '/wordings/resource_template',
				type: 'POST',
				data: params,
				success: function (response) {
					$('#geobase_filter').removeClass('dn').html(response);
					$('#geobase_filter select.form-control').select2();
				},
				error: function () {
					$('#geobase_filter').addClass('dn').html('');
				}
			});
		}
	});
});
