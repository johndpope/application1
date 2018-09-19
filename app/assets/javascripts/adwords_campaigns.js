$(function () {
	$('select').select2();
	$(document).ready(function () {
		isForm('adwords_campaign', true, true);
		$(".select2-container").addClass('form-control');
	});

	$('#adwords_campaign_languages').on('change', function () {
		var languages_values = $(this).val();
		if (languages_values != null && languages_values[0] == 'all-languages') {
			$('#adwords_campaign_languages').select2('val', ['all-languages']);
		}
	});

	$('#adwords_campaign_campaign_type').on('change', function () {
		if ($(this).val() == 5) {
			$('#subtype_block').show();
		} else {
			$('#subtype_block').hide();
		}
	});
});
