//= require jquery.counter.js
//= require jquery.justifiedGallery.min.js
//= require fancybox2

var ready = function() {
	function tags() {
		// Color tags
		var attr = ['tb-red', 'tb-gray tb-gray-one', 'tb-black', 'tb-gray tb-gray-two'];
		var atl = attr.length;
		var al = $('.box-content-ah.cvd-tags b').length;

		for (var i = 0, el = 0; el <= al; i++, el++) {
			if (i == atl) i = 0;
			$('.box-content-ah.cvd-tags b:eq(' + el + ')').addClass(attr[i]);
		}
	}

	if ($('.box-content-ah.cvd-tags b').length) tags();

	// jQuery Counter.js
	$('#counter').addClass('counter-analog').counter({format: '99999'});

	$('#campaign_localities').on('change', function() {
		combo = $(this);

		$.get(combo.attr('data-url'), { locality_id: combo.find('option:selected').val() }, function(response) {
			$('#locality_campaign_video_sets').html(response);
		});
	});

	$('#btn_spin').on('click', function() {
		window.location.href = $('#locality_campaign_video_sets option:selected').attr('data-url');
	});

	$("#output_samples_box").justifiedGallery({
		rowHeight : 200,
	    lastRow : 'justify',
	    margins : 2
	});

	$('#output_samples_box a.fancybox-button').fancybox();
}

$(document).ready(ready);
$(document).on('page:load', ready);


/*---- Content blender ----*/
$('.fragments-of-history:first').css({'display': 'block'});

function linePosition(hero) {
	var it = hero.index();
	var href = hero.attr('href');

	// likes, dislikes, comments, share, counter, browser
	var dataJSON = JSON.parse(hero.attr('data-json'));
	var hasA = hero.hasClass('active');

	// https://github.com/garethdn/jquery-numerator
	if (dataJSON.views != null) {
		$('#counter').counter('stop');
		$('#counter').counter({
			initial: (dataJSON.views - 1000),
			direction: 'up',
			interval: 1000,
			format: '99999',
			stop: dataJSON.views
		});
	}

	$('#likes').html(dataJSON.likes);
	$('#dislikes').html(dataJSON.dislikes);
	$('#comments').html(dataJSON.comments);
	$('#share').html(dataJSON.shares);
	$('#position').html(dataJSON.position);
	$('#ltp img').attr('src', dataJSON.browser);

	$('.line-position a').each(function(index, element) {
		$(element).removeClass();
	});

	$('.fragments-of-history').each(function(index, element) {
		$(element).css('display', 'none');
	});

	for (var i = 0; i <= it; i++) {
		$('.line-position a:eq(' + i + ')').addClass('active');
		$(href).css('display', 'block');
	}

	hero.addClass('now');

	var lineSize = ($('.line-position').width() / ($('.line-position a').length - 1)) * it;

	$('.line-position .lp-active').css('width', lineSize + 'px');
}

$('#cvd-next').click(function() {
	var next = $('.line-position a.active').last().next('a');

	if (next.index() == -1) next = $('.line-position a').first();
	if (next.length >= 1) linePosition(next);
});

$('.line-position a').click(function(event) {
	event.preventDefault();

	if ($(this).hasClass('now')) return false;

	linePosition($(this));
});

function timelineMonth() {
	// var colA = $('.line-position > a').length;
	if ((colA = $('.line-position > a').length) > 0) {
		var width = $('.line-position').width() - (colA-- * 66);
		var marginEl = width / colA;

		$('.line-position > a').css('margin-left', Math.round(marginEl)).last().css({
			'float': 'right',
			'margin': 0
		});
	} else {
		$('.line-position').remove();
	}
}

timelineMonth();
