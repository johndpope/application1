// Timeline statistics
function synchronise_timeline_details() {
	var duration = 0;

	$('#timeline .media-item').each(function(index, element) {
		duration += parseInt((JSON.parse($(element).attr('data-json'))).duration);
	});

	$('#timeline_total_time').text((new Date).clearTime().addSeconds(duration).toString('H:mm:ss'));
	$('#timeline_elements_nr').text($('#timeline .media-item').length);
}

function regenerate_timeline(){
	var pattern = $('#btn_regenerate').data('pattern');

	getRandom = function(max) {
		return Math.floor(Math.random() * max);
	}

	$('#timeline').html("");
	$.each(pattern, function(index,item){
		var class_name = ".media-type-" + item;
		if ($(class_name).length != 0){
			var random = getRandom($(class_name).length);
			var media_item = $(class_name).eq(random).clone(true)[0];
			$('#timeline').append(media_item);
		}
	});
	synchronise_timeline_details();
}

$(function() {
	// Temporary replacement function Draggable
	$('.panel .set').sortable({
		connectWith: '#timeline',
		placeholder: 'sortable-placeholder',
		appendTo: 'body',
		helper: function(e, li) {
			this.copyHelper = li.clone().insertAfter(li);
			$(this).data('copied', false);
			return li.clone();
		},
		stop: function() {
			var copied = $(this).data('copied');
			if (!copied) this.copyHelper.remove();
			this.copyHelper = null;
		}
	});

	// Sort video clips in the Timeline
	$('#timeline').sortable({
		revert: '100',
		axis: 'x',
		scroll: true,
		tolerance: 'intersect',
		placeholder: 'sortable-placeholder',
		receive: function (e, ui) {
			ui.sender.data('copied', true);
			synchronise_timeline_details();
			$('#timelineClearAll').removeClass('btn-gray').addClass('btn-red');
		}
	});

	// Clear timeline of all video clips
	$('#timelineClearAll').click(function() {
		$('#timeline').html('');
		synchronise_timeline_details();
		$(this).removeClass('btn-red').addClass('btn-gray');
	});

	// Remove video fragment
	$('body').on('click', '.media-item i.remove', function() {
		$(this).closest('.media-item').remove();
		synchronise_timeline_details();
		if ($('#timeline .media-item').length <= 0) $('#timelineClearAll').removeClass('btn-red').addClass('btn-gray');
	});

	$('#btn_blend').click(function(event) {
		event.preventDefault();
		btn = $(this).find('> span');
		btn_download = $('#btn_download');
		videosUrl = $.map($('#timeline .media-item'), function(e) {
			return (JSON.parse($(e).attr('data-json'))).videos;
		});

		btn.html('Blending ...');

		$.post($(this).attr('href'), { videos: videosUrl, authenticity_token: $('[name="csrf-token"]').attr('content') }, function(response) {
			$('.video-js .vjs-big-play-button').css('display', 'none');
			$('.vjs-tech').attr('src', response.video).first().trigger('play');
			btn.html('Blend');
			btn_download.attr('href', response.video).attr('download', response.video);
			btn_download.removeClass('btn-gray').addClass('btn-green');
		}).fail(function() {
			btn.html('Failed. Try again');
		}).always(function() {
			btn.html('<b>Blend</b>It');
		});
	});

	// Modal window - info
	$('body').on('click', '.media-item .black-title, .media-item img', function() {
		$('#infoBox').modal('show');
		body = $('#infoBox .modal-body');
		url = (JSON.parse($(this).closest('.media-item').attr('data-json'))).action;

		$.get(url, function(response) {
			body.html(response);
		}).fail(function() {
			body.html('<div class="alert alert-danger">Failed to load info.</div>');
		});
	});

	$('#infoBox').on('hidden.bs.modal', function(e) {
		$('#infoBox .modal-body').html('');
	});

	// Drop-down menu with a list of cities
	$('#localities').select2({
		allowClear: true,
		placeholder: 'Filter by city ...'
	}).on('change', function() {
		val = $(this).val();
		if (val === '') {
			$('.media-item[data-location-id]').show();
		} else {
			$('.media-item[data-location-id]').hide();
			$('.media-item[data-location-id="' + val + '"]').show();
		}
	}).val($('option:not(:empty):first', $(this)).val()).trigger("change");

	// Sniped library: Top margin to scroll
	$(function() {
		it = $('.tab-content.excerpts');
		it.css('max-height', 'calc(100% - ' + it.position().top + 'px)');
	});

	synchronise_timeline_details();

	$('[data-toggle="popover"]').popover({
		content: $(this).data('content'),
		html: true,
		placement: 'top',
		container: 'body',
		trigger: 'hover'
	});

	var owl = $("#owl-demo-2");

  owl.owlCarousel({
		items : 1,
		itemsCustom : false,
    itemsDesktop : [1199,1],
		afterMove: function(e){
			var current = this.currentItem;
			$('.nav_item i').removeClass('fa-circle').addClass('fa-circle-thin');
			$('.nav_item i').eq(current).removeClass('fa-circle-thin').addClass('fa-circle');
		}
  });

	$('.nav_left').click(function(e){
		owl.trigger('owl.prev');
	});

	$(".nav_right").click(function(){
		owl.trigger('owl.next');
	});

	$('.nav_item').click(function(){
		owl.trigger('owl.goTo', $(this).index()-1);
		$('.nav_item i').removeClass('fa-circle').addClass('fa-circle-thin');
		$(this).find('i').removeClass('fa-circle-thin').addClass('fa-circle');
	});

	$('.help_link').on('click', function(){
		$('#info_popover').toggle();
	});

	$('.close_btn').on('click', function(){
		$(this).closest('#info_popover').fadeOut();
	});

	$(document).on('click', function (e) {
		if ( ($(e.target).closest('#info_popover').length === 0) && ($(e.target).closest('.help_link').length != 1)){
			$('#info_popover').fadeOut();
		}
	});

	$('#accordion').on('show.bs.collapse', function(e){
		$(e.target).closest('.panel').find('.corner').removeClass('fa-caret-right').addClass('fa-caret-down');
	}).on('hidden.bs.collapse', function(e){
		$(e.target).closest('.panel').find('.corner').removeClass('fa-caret-down').addClass('fa-caret-right');
	});

	$('#btn_shuffle').click(function(){
		$('#timeline .media-item').shuffle()
	})

	$('#btn_regenerate').on('click', regenerate_timeline);

	$('a.step').on('click', function(e){
		$('a.step').removeClass('current');
		$(e.target).addClass('current');
	});

	$('.float-right').on('click',function(){
		var it_next = $('.current').next();
		$('.step').removeClass('current');
		if (it_next.index() == -1){
			$('.step').last().addClass('current');
			next_link = $('.step').last().attr('href');
		}else{
			it_next.addClass('current');
			next_link = $(it_next).attr('href');
		}
		$('.arrow-steps a[href=' + next_link + ']').tab('show');
	});

	$('.float-left').on('click', function(){
		var it_prev = $('.current').prev();
		$('.step').removeClass('current');

		if (it_prev.index() == -1){
			prev_link = $('.step').first().attr('href');
			$('.step').first().addClass('current');
		}else{
			prev_link = $(it_prev).attr('href');
			it_prev.addClass('current');
		}
		$('.arrow-steps a[href=' + prev_link + ']').tab('show');
	});


	$('.youtube_setup_collapse_widget').on('shown.bs.collapse', function (e){
		$(e.target).closest('.panel-heading').find('.collapsed_row').addClass('hidden');
		$(e.target).closest('.panel-heading').find('.collapse_link').removeClass('arrow-down').addClass('arrow-up');
	}).on('hide.bs.collapse', function (e){
		$(e.target).closest('.panel-heading').find('.collapsed_row').removeClass('hidden');
		$(e.target).closest('.panel-heading').find('.collapse_link').removeClass('arrow-up').addClass('arrow-down');
	});


	$('.template_img').on('click', function(e){
		var channel_art_src = $(e.target).data('src');
		$('.channel_art_container a').attr('href',channel_art_src);
		$('body').find('.channel_art_selected').attr('src',channel_art_src);
		$('.template_img').removeClass('active');
		$(e.target).addClass('active');
	});

	var thumbnail_src = $('.selected_thumbnail').attr('src');
	var esrc = $('#video1_html5_api').attr('src');

	$('.thumbnail_img').on('click', function(e){
		var th_src = $(e.target).data('src');
		$('body').find('.selected_thumbnail').attr('src', th_src);
		$('body').find('.selected_thumbnail').first().parent().attr('href', th_src);
		$('.thumbnail_img').removeClass('active');
		$(e.target).addClass('active');

		src = $('#video1_html5_api').attr('src');
		$('body').find('#video2_html5_api').attr('src', src).attr('poster',th_src);
		$('body').find('#video3_html5_api').attr('src', src).attr('poster',th_src);
	});


	$('.ytb_icon')
		.mouseover(function(e){
			var ic = $(e.target).data('mouseover');
			$(e.target).attr('src', ic);
		})
		.mouseout(function(e){
			var pt = $(e.target).data('mouseout')
			$(e.target).attr('src', pt);
		});

	$('#collapseDescription').on('show.bs.collapse',function(){
		$('.short').hide();
	}).on('hide.bs.collapse', function(){
		$('.short').show();
	});


});
