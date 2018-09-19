$(function () {
  var start_time_hours = $('#start_time_hours');
	var start_time_minutes = $('#start_time_minutes');
	var start_time_seconds = $('#start_time_seconds');
  var youtube_video_card_start_time = $('#youtube_video_card_start_time');

	$('select').select2();

	$(document).ready(function () {
		$('.select2-container').addClass('form-control');
    setTimeFromSeconds(youtube_video_card_start_time, start_time_hours, start_time_minutes, start_time_seconds);
    hideFields();
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
			$('#youtube_video_card_start_time').val(seconds);
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
			$('#youtube_video_card_start_time').val(seconds);
		}
	});

	$('#start_time_hours').spinner({
		min: 0,
		change: function (event, ui) {
			seconds = convertToSeconds(start_time_hours, start_time_minutes, start_time_seconds);
			$('#youtube_video_card_start_time').val(seconds);
		}
	});

  function hideFields(){
    var card_type = $('#youtube_video_card_card_type')
    if (card_type.val() == 1) {
      $('#card_image_div').hide();
      $('#custom_message_div').hide();
      $('#card_title_div').hide();
      $('#call_to_action_div').hide();
      $('#teaser_text_div').hide();
    } else if (card_type.val() == 2) {
      $('#card_image_div').hide();
      $('#custom_message_div').show();
      $('#card_title_div').hide();
      $('#call_to_action_div').hide();
      $('#teaser_text_div').show();
    } else if (card_type.val() == 3){
      $('#card_image_div').show();
      $('#custom_message_div').hide();
      $('#card_title_div').show();
      $('#call_to_action_div').show();
      $('#teaser_text_div').show();
    }
  }

	$('#youtube_video_card_card_type').on('change', function () {
    hideFields();

		$('#youtube_video_card_custom_message').val('');
		$('#youtube_video_card_url').val('');
		$('#youtube_video_card_call_to_action').val('');
		$('#youtube_video_card_card_title').val('');
    $('#youtube_video_card_teaser_text').val('');
	});
});
