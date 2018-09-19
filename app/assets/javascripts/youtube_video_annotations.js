$(function () {
	var start_time_hours = $('#start_time_hours');
	var start_time_minutes = $('#start_time_minutes');
	var start_time_seconds = $('#start_time_seconds');
	var end_time_hours = $('#end_time_hours');
	var end_time_minutes = $('#end_time_minutes');
	var end_time_seconds = $('#end_time_seconds');
	var link_start_time_hours = $('#link_start_time_hours');
	var link_start_time_minutes = $('#link_start_time_minutes');
	var link_start_time_seconds = $('#link_start_time_seconds');

	var youtube_video_annotation_start_time = $('#youtube_video_annotation_start_time');
	var youtube_video_annotation_end_time = $('#youtube_video_annotation_end_time');
	var youtube_video_annotation_link_start_time = $('#youtube_video_annotation_link_start_time');

	$('select').select2();

	$(document).ready(function () {
		$('.select2-container').addClass('form-control');
		setTimeFromSeconds(youtube_video_annotation_start_time, start_time_hours, start_time_minutes, start_time_seconds);
		setTimeFromSeconds(youtube_video_annotation_end_time, end_time_hours, end_time_minutes, end_time_seconds);
		setTimeFromSeconds(youtube_video_annotation_link_start_time, link_start_time_hours, link_start_time_minutes,
		link_start_time_seconds);
	});

	function setTimeFromSeconds(hidden_field, hours_element, minutes_element, seconds_element) {
		hidden_field_value = hidden_field.val();
		if (hidden_field_value != '' && hidden_field_value != 'undefined') {
			h = Math.floor(hidden_field_value / 3600);
			m = Math.floor((hidden_field_value - (h * 3600)) / 60);
			s = hidden_field_value - (h * 3600) - (m * 60);
			hours_element.spinner('value', h);
			minutes_element.spinner('value', m);
			seconds_element.spinner('value', s);
		}
	}

	function convertToSeconds(hours, minutes, seconds) {
		hh = hours.spinner('value');
		mm = minutes.spinner('value');
		ss = seconds.spinner('value');
		final = hh * 60 * 60 + mm * 60 + ss;
		return final;
	}

	$('#start_time_seconds').spinner({
		spin: function (event, ui) {
			if (ui.value >= 60) {
				$(this).spinner('value', ui.value - 60);
				$('#start_time_minutes').spinner('stepUp');
				return false;
			} else if (ui.value < 0) {
				$(this).spinner('value', ui.value + 60);
				$('#start_time_minutes').spinner('stepDown');
				return false;
			}
		},
		change: function (event, ui) {
			seconds = convertToSeconds(start_time_hours, start_time_minutes, start_time_seconds);
			$('#youtube_video_annotation_start_time').val(seconds);
		}
	});

	$('#start_time_minutes').spinner({
		spin: function (event, ui) {
			if (ui.value >= 60) {
				$(this).spinner('value', ui.value - 60);
				$('#start_time_hours').spinner('stepUp');
				return false;
			} else if (ui.value < 0) {
				$(this).spinner('value', ui.value + 60);
				$('#start_time_hours').spinner('stepDown');
				return false;
			}
		},
		change: function (event, ui) {
			seconds = convertToSeconds(start_time_hours, start_time_minutes, start_time_seconds);
			$('#youtube_video_annotation_start_time').val(seconds);
		}
	});

	$('#start_time_hours').spinner({
		min: 0,
		change: function (event, ui) {
			seconds = convertToSeconds(start_time_hours, start_time_minutes, start_time_seconds);
			$('#youtube_video_annotation_start_time').val(seconds);
		}
	});

	$('#end_time_seconds').spinner({
		spin: function (event, ui) {
			if (ui.value >= 60) {
				$(this).spinner('value', ui.value - 60);
				$('#end_time_minutes').spinner('stepUp');
				return false;
			} else if (ui.value < 0) {
				$(this).spinner('value', ui.value + 60);
				$('#end_time_minutes').spinner('stepDown');
				return false;
			}
		},
		change: function (event, ui) {
			seconds = convertToSeconds(end_time_hours, end_time_minutes, end_time_seconds);
			$('#youtube_video_annotation_end_time').val(seconds);
		}
	});

	$('#end_time_minutes').spinner({
		spin: function (event, ui) {
			if (ui.value >= 60) {
				$(this).spinner('value', ui.value - 60);
				$('#end_time_hours').spinner('stepUp');
				return false;
			} else if (ui.value < 0) {
				$(this).spinner('value', ui.value + 60);
				$('#end_time_hours').spinner('stepDown');
				return false;
			}
		},
		change: function (event, ui) {
			seconds = convertToSeconds(end_time_hours, end_time_minutes, end_time_seconds);
			$('#youtube_video_annotation_end_time').val(seconds);
		}
	});

	$('#end_time_hours').spinner({
		min: 0,
		change: function (event, ui) {
			seconds = convertToSeconds(end_time_hours, end_time_minutes, end_time_seconds);
			$('#youtube_video_annotation_end_time').val(seconds);
		}
	});

	$('#link_start_time_seconds').spinner({
		spin: function (event, ui) {
			if (ui.value >= 60) {
				$(this).spinner('value', ui.value - 60);
				$('#link_start_time_minutes').spinner('stepUp');
				return false;
			} else if (ui.value < 0) {
				$(this).spinner('value', ui.value + 60);
				$('#link_start_time_minutes').spinner('stepDown');
				return false;
			}
		},
		change: function (event, ui) {
			seconds = convertToSeconds(link_start_time_hours, link_start_time_minutes, link_start_time_seconds);
			$('#youtube_video_annotation_link_start_time').val(seconds);
		}
	});

	$('#link_start_time_minutes').spinner({
		spin: function (event, ui) {
			if (ui.value >= 60) {
				$(this).spinner('value', ui.value - 60);
				$('#link_start_time_hours').spinner('stepUp');
				return false;
			} else if (ui.value < 0) {
				$(this).spinner('value', ui.value + 60);
				$('#link_start_time_hours').spinner('stepDown');
				return false;
			}
		},
		change: function (event, ui) {
			seconds = convertToSeconds(link_start_time_hours, link_start_time_minutes, link_start_time_seconds);
			$('#youtube_video_annotation_link_start_time').val(seconds);
		}
	});

	$('#link_start_time_hours').spinner({
		min: 0,
		change: function (event, ui) {
			seconds = convertToSeconds(link_start_time_hours, link_start_time_minutes, link_start_time_seconds);
			$('#youtube_video_annotation_link_start_time').val(seconds);
		}
	});
});
