window.sandbox_home_index = ->
	$('#sp-id').sliderPro
		width: '100%',
		height: 715,
		fade: false,
		autoplay: false,
		autoplayDelay: 1000,
		arrows: true,
		buttons: false,
		thumbnailArrows: true
	.on 'gotoSlide', (e) ->
		idx = e.index;
		$('.media-block').removeClass('active')
		$('[data-id=' + idx + ']').addClass('active');
		video_url = $('[data-id=' + idx + '] .part1 a').data('url');
		$('#video3 video').attr('src',video_url);
		$('#video3 video').load();
		$('#video3 video').trigger('play');
		$('.vjs-big-play-button').css('display',"none");

	$('.slide-item').on "click", (e) ->
		slide_index = $(this).closest('.media-block').data('id');
		$('#sp-id').sliderPro('gotoSlide', slide_index);
		$('.media-block').removeClass('active');
		$('[data-id=' + slide_index + ']').addClass('active');

	$('.go_to_section').on "click", (event) ->
		event.preventDefault();
		id = $(this).attr('href');
		top = $(id).offset().top;
		$('body,html').animate({scrollTop: top}, 500);

	$('.slide-item, .coming_soon_link, .sp-btn').on 'click', (e) ->
		$('#video3 video').attr('src', $(this).data('url'));
		$('#video3 video').load();
		$('#video3 video').trigger('play');
		$('.vjs-big-play-button').css('display',"none");

	$('.coming_soon_popover').popover
		trigger: 'hover',
		placement: 'bottom',
		content: "Coming soon"

	scroll_top_duration = 700
	$('.scroll-up').on "click", (event) ->
		$('body,html').animate { scrollTop: 0 }, scroll_top_duration
		return

	$(window).load ()->
		$('.video_container').removeClass('hidden');

	$(window).scroll ()->
		y = $(window).scrollTop();
		if (y >= 300)
			$('.scroll-up').removeClass('hidden');
		else
			$('.scroll-up').addClass('hidden');

	gifImg = new freezeframe('.my_class_3').capture().setup();
	gifImg.release();

	$('.my_class_3').on "click", (e)->
		if ($('.ff-canvas').hasClass("ff-canvas-active"))
			$(".ff-overlay").removeClass('hidden');
			e.preventDefault();
			gifImg.release();

		else
			$(".ff-overlay").addClass('hidden');
			e.preventDefault();
			gifImg.trigger();

	$('#try-blender-images').on "click", (e)->
		if $(this).attr("value") == 'pause'
			$(".ff-overlay").addClass('hidden');
			$(this).attr("value",'play');
			e.preventDefault();
			gifImg.trigger();
		else
			$(".ff-overlay").removeClass('hidden');
			$(this).attr("value",'pause');
			e.preventDefault();
			gifImg.release();


window.sandbox_home_how_it_works = ->
	# Modals
	$('.img-tb').on "click", (event) ->
		event.preventDefault();
		e = $(this);
		i = e.attr('href');
		parent = e.parent();
		title = parent.find('.text-title').text();
		description = parent.find('.text-description').text();
		$('body').append('<div id="modal-lg" class="modal fade"><div class="modal-dialog modal-lg"><div class="modal-content"><div class="modal-header"><button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button><h4 class="modal-title">' + title + '</h4></div><div class="modal-body"><video autoplay="autoplay" class="video-js vjs-default-skin" controls="controls" preload="auto" data-setup="{}" width="100%" height="483"><source src="/system/sandbox/demo_video/echo_video_' + i + '.mp4" type="video/mp4" /></video><p class="lead text-description">' + description + '</p></div></div></div></div>');
		$('#modal-lg').modal('show');

	$(document).on 'hide.bs.modal', (e) ->
		$('#modal-lg').remove();
		$('body').removeClass('modal-open');
