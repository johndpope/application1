var ready = function () {
	$('select').select2({ allowClear: true });
	$('.select2-container').addClass('form-control');
}

$(document).ready(ready);
$(document).on('page:load', ready);
