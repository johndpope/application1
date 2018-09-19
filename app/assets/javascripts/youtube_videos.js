//= require jquery-live-preview
//= require fancybox

fancybox_settings = {
  helpers: {
    title : {
      type : 'float'
    }
  }
}

$(function () {
	var HEIGHT_LIMIT = 100;
	var collapse_text = 'Collapse';
	var expand_text = 'Expand';

	$(document).ready(function () {
    $(".image-preview").fancybox(fancybox_settings);
    
		$('.numeric').keypress(function (e) {
			if (e.which != 13 && e.which != 8 && e.which != 0 && (e.which < 48 || e.which > 57)) return false;
		});

		$('.livepreview.left-livepreview').livePreview({
			position: 'left'
		});

		$('.livepreview').livePreview();

		makeASmallSitebar('auto');
	});

	$('#youtube_videos_list .link').on('click', function () {
		var youtube_video_id = $(this).data('id');
		var youtube_video_link = $(this);

		$.ajax({
			type: 'patch',
			dataType: 'json',
			url: '/youtube_videos/' + youtube_video_id + '?youtube_video[linked]=true',
			contentType: 'json'
		}).done(function (response) {
			youtube_video_link.parent().parent().remove();
		});
	});

	$('body').on('click','.collapse-expand-link', function () {
		parent_wrapper = $(this).siblings('.fluent-wrapper');

		if ($(this).attr('data-state') == 'collapsed') {
			$(this).attr('data-state', 'expanded');
			$(this).text(collapse_text);
			parent_wrapper.removeClass('limited');
		} else {
			$(this).attr('data-state', 'collapsed');
			$(this).text(expand_text);
			parent_wrapper.addClass('limited');
		}
	});

	$('.fluent-container').each(function (index, el) {
		el = $(el);
		if (el.height() > HEIGHT_LIMIT) {
			el.closest('td').append('<a href="javascript://" data-state="collapsed" class="collapse-expand-link">Expand</a>');
		}
	});

	var order_by = $('#filter_order');
	var order_type = $('#filter_order_type');
	var th = $('#' + order_by.val() + '-th');

	if (th !== 'undefined') th.addClass('sort_' + order_type.val());

	var filter = $('#filter');
	var filter_settings = $('#filter_settings');

	filter.click(function () {
    var open = false;
    if (!$(this).hasClass("open")) {
      $(this).animate({ 'right': '250px' });
      filter_settings.animate({ 'right': '0' });
      $(this).addClass("open");
      open = true;
    } else {
      $(this).animate({ 'right': '0' });
      filter_settings.animate({ 'right': '-250px' });
      $(this).removeClass("open");
    }

		if (typeof(Storage) != 'undefined') {
			if (open) {
				localStorage.setItem('youtube-videos-filter-settings-open', 'true');
			} else{
				localStorage.setItem('youtube-videos-filter-settings-open', 'false');
			}
		} else {
			console.log('Sorry, your browser does not support Web Storage...');
		}
	});

	if (typeof(Storage) != 'undefined' && localStorage.getItem('youtube-videos-filter-settings-open') == 'true') {
    filter.animate({ 'right': '250px' });
    filter_settings.animate({ 'right': '0' });
    filter.addClass("open");
	}

	regions_url = $('#regions_url').val();

	$('body').on('click', '*[data-legend-url]', function (event) {
		if (filter.hasClass('open')) {
			filter.css('right', 0);
			filter_settings.css('right', '-250px');
			filter.removeClass('open');
		}

		element = $(this);
		$('#youtube_video_legend').empty();
		$.ajax({ url: element.data('legend-url') }).done(function (response) {
			$('#youtube_video_legend').append(response).modal();
		});
	});

	$('select').select2({ allowClear: true });
	$('#country_id').on('change', function () {
		country_id = $(this).val();
		$('#region_id').attr('disabled', 'disabled').html('');
		$.ajax({
			type: 'GET',
			url: regions_url + '/' + country_id
		}).done(function (response) {
			$('#region_id').html(response);
			var selection = $('#s2id_region_id').find('.select2-chosen');
			selection.text('');
		}).always(function (e) {
			$('#region_id').removeAttr('disabled');
		});
	});

	$('#youtube_videos_table th').on('click', function () {
		if ($(this).hasClass('sort')) {
			var data_field = $(this).attr('data-field');

			if ($(this).hasClass('sort_asc')) {
				$('#youtube_videos_table th').removeClass('sort_asc').removeClass('sort_desc');
				$(this).removeClass('sort_asc').addClass('sort_desc');
				order_type.select2('val', 'desc');
			} else {
				$('#youtube_videos_table th').removeClass('sort_asc').removeClass('sort_desc');
				$(this).removeClass('sort_desc').addClass('sort_asc');
				order_type.select2('val', 'asc');
			}

			order_by.select2('val', data_field);
			$('#filters_form').submit();
		}
	});
});
