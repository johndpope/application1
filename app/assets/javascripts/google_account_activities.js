$(function () {
	$('#google_account_activities_table .link').on('click', function () {
		var google_account_activity_id = $(this).data('id');
		var google_account_activity_link = $(this);

		$.ajax({
			type: 'PATCH',
			dataType: 'json',
			url: '/google_account_activities/' + google_account_activity_id + '?google_account_activity[linked]=true',
			contentType: 'json'
		}).done(function (response) {
			google_account_activity_link.parent().parent().remove();
		}).fail(function (response) {});
	});
});
