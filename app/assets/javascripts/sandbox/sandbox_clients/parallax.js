// Illustration by http://psdblast.com/flat-color-abstract-city-background-psd
$(window).on('mousemove', function(e) {
	var w = $(window).width();
	var h = $(window).height();
	var offsetX = 0.5 - e.pageX / w;
	var offsetY = 0.5 - e.pageY / h;

	$('.parallax').each(function(i, el) {
		var offset = parseInt($(el).data('offset'));

		var one = Math.round(offsetX * offset);
		if (one <= '-75') one = '-75'; else if (one >= 50) one = 50;
		var two = Math.round(offsetY * offset);
		if (two <= '-75') two = '-75'; else if (two >= 50) two = 50;

		var translate = 'translate3d(' + one + 'px,' + two + 'px, 0px)';

		$(el).css({
			'-webkit-transform': translate,
			'transform': translate,
			'moz-transform': translate
		});
	});
});
