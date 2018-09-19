/*---- Campaign view ----*/
$('.campaign-view').on('click', '.city_select_bg:not(.active)', function() {
	var t = $(this);
	var dataJSON = JSON.parse(t.attr('data-json'));

	$('.city_select_bg.active').each(function() {
		var t = $(this);
		var dataJSON = JSON.parse(t.attr('data-json'));

		t.removeClass('active');
		t.find('.swing').hide();
		t.find('.default').show();
		t.css("background-image", "url('" + dataJSON.background[0] + "')");
	});

	t.addClass('active');
	t.find('.default').hide();
	t.find('.swing').show();
	t.css("background-image", "url('" + dataJSON.background[1] + "')");

	if (t.find('.swing').length == 0) {
		$.get(dataJSON.url, function(response) {
			var index = t.index() - 1;

			t.remove();
			$('.city_select_bg:eq(' + index + ')').after(response);
		});
	}

	return false;
});
