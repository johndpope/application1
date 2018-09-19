//= require jquery_ujs
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
}

$(document).ready(ready);
$(document).on('page:load', ready);
