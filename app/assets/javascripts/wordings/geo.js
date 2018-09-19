function display_each (element) {
	var val = element.val().toLowerCase();
	var display = 'block';

	$('.select2-ajax').each(function () {
		e = $(this);
		e.parent().css('display', display);
		if (val == e.data('type')) display = 'none';
	});
}

$(function () {
	display_each($('#resource_type'));

	$('#resource_type').change(function () {
		display_each($(this));
	});

	$('#search').click(function () {
		object = { 'type': $('#resource_type').val() };

		$('.select2-ajax').each(function () {
			value = $(this).val();
			if ($(this).parent().css('display') == 'block' && value) object[$(this).attr('name')] = value;
		});

		location.href = '/geo?' + jQuery.param(object);
	});

	$('.select2-ajax').select2({
		dropdownCssClass: 'bigdrop',
		minimumInputLength: 3,
		allowClear: true,
		ajax: {
			url: '/geobase/search',
				dataType: 'json',
				data: function (term) {
					object = {
						'type': $(this).data('type'),
						'query': term
					};

					$('.select2-ajax').each(function () {
						value = $(this).val();
						if ($(this).parent().css('display') == 'block' && value) object[$(this).attr('name')] = value;
					});

					return object;
				},
				results: function (data) {
					return { 'results': data };
				}
			},
			initSelection: function (item, callback) {
				id = item.val();
				type = item.data('type');

				if (id !== '') {
					$.ajax('/geobase/search', {
						data: {
							'type': type,
							'id': id
						},
						dataType: 'json'
					}).done(function (data) {
						callback(data);
					});
				}
			},
			formatResult: function (item) {
				return item.name;
			},
			formatSelection: function (item) {
				return item.name;
			},
			escapeMarkup: function (m) {
				return m;
			}
	});
});
