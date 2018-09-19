$.fn.serializeObject = function (type) {
	var o = {};
	var a = this.serializeArray();

	$.each(a, function() {
		if ($.inArray(this.name, ['utf8', 'authenticity_token', 'value']) == -1) {
			name = this.name.replace('youtube_video_' + type + '_template[', '').replace(']', '');

	        if (o[name] !== undefined) {
	            if (!o[name].push) o[name] = [o[name]];
	            o[name].push(this.value || '');
	        } else {
	            o[name] = this.value || '';
	        }
		}
    });

    return o;
};

function calcTemplates (type, limit) {
	lg = $('#table_' + type + '_templates > tbody > tr[data-json]').length;
	add_button = $('#add_' + type);
	is_disabled = add_button.hasClass('disabled');

	if (lg >= limit) {
		if (!is_disabled) add_button.addClass('disabled');
	} else {
		if (is_disabled) add_button.removeClass('disabled');
	}
}

function reIndex (ajax, type) {
	elements = $(document).find('#partial_' + type + '_template table#table_' + type + '_templates > tbody > tr');
	template = [];

	elements.each(function (index, element) {
		e = $(element);

		if (e.attr('data-json')) {
			e.attr('data-id', index);
			template.push(e.attr('data-json'));
		}
	});

	$('input[name="youtube_setup[youtube_video_' + type + '_templates_attributes]"]').val('[' + template + ']');

	if (ajax) {
		template = $('input[name="youtube_setup[youtube_video_' + type + '_templates_attributes]"]').val();

		$.ajax({
			url: '/youtube_setups/video_template_list',
			data: {
				'array_of_jsons': template,
				'type': type
			},
			type: 'post',
			success: function (data) {
				$('#partial_' + type + '_template').html(data);
				if (type == 'card') calcTemplates('card', 5);
			}
		});
	} else {
		if (type == 'card') calcTemplates('card', 5);
	}
};

$(function () {
	reIndex(false, 'annotation');
	reIndex(false, 'card');

	$('#modalYVT').on('show.bs.modal', function (e) {
		if (type = $(this).attr('data-type')) {
			strJSON = (sessionStorage.nowID) ? $('table#table_' + type + '_templates > tbody > tr:eq(' + sessionStorage.nowID + ')').attr('data-json') : '{}';

			$.ajax({
				url: '/youtube_setups/video_template_form',
				data: {
					'json': strJSON,
					'type': type
				},
				type: 'post',
				success: function (data) {
					$('#modalYVT .modal-body').html(data);
					window['render_' + type]();
					$('#modalYVT select').select2();
				}
			});
		} else {
			alert('Error: Undefined attribute "data-type".');
			return false;
		}
	});

	$('#modalYVT').on('hidden.bs.modal', function (e) {
		$('#modalYVT .modal-body').html('');
	});

	$(document).on('click', '.getModal', function () {
		if (type = $(this).attr('data-type')) {
			(id = $(this).closest('tr').attr('data-id')) ? sessionStorage.setItem('nowID', id) : sessionStorage.removeItem('nowID');
			modal = $('#modalYVT');
			modal.find('.modal-title').html('Add ' + type + ' template');
			modal.attr('data-type', type);
			modal.modal('show');
		} else {
			alert('Error: Undefined attribute "data-type".');
		}
	});

	$(document).on('click', '#create_or_save', function () {
		var type = $('#modalYVT').attr('data-type');
		var getFormObject = $('form.new_youtube_video_' + type + '_template').serializeObject(type);
		var getJsonFromObject = JSON.stringify(getFormObject);
		var tableTbody = $('table#table_' + type + '_templates tbody');

		$.ajax({
			url: '/youtube_setups/video_template_form',
			data: {
				'json': getJsonFromObject,
				'type': type
			},
			type: 'post',
			error: function (data) {
				$('#modalYVT .modal-body').html(data.responseText);
				window['render_' + type]();
				$('#modalYVT select').select2();
			},
			success: function () {
				$('#modalYVT').modal('hide');

				if (sessionStorage.nowID) {
					modifyingNow = $('table#table_' + type + '_templates tbody tr:eq(' + sessionStorage.nowID + ')');
					modifyingNow.attr('data-json', getJsonFromObject);
				} else {
					tr = '<tr><td class="center" colspan="5"><b>Loading... Please wait!</b></td></tr>';
					tableTbody.append(tr);
					tableTbody.find('tr:last').attr('data-json', getJsonFromObject);
				}

				reIndex(true, type);
			}
		});
	});

	$(document).on('click', '.delete', function () {
		if (confirm('Are you sure?')) {
			if (type = $(this).attr('data-type')) {
				tr = $(this).closest('tr');
				json = jQuery.parseJSON(tr.attr('data-json'));

				if (json.id) {
					$.ajax({
						url: '/youtube_video_' + type + 's/' + json.id + '/',
						type: 'delete',
						dataType: 'json',
						success: function () {
							tr.remove();
							reIndex(true, type);
						}
					});
				} else {
					tr.remove();
					reIndex(true, type);
				}
			} else {
				alert('Error: Undefined attribute "data-type".');
			}
		} else {
			return false;
		}
	});
});
