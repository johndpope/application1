function render_annotation () {
	function convertToSeconds (hours, minutes, seconds) {
		hh = hours.spinner('value');
		mm = minutes.spinner('value');
		ss = seconds.spinner('value');
		final = hh * 60 * 60 + mm * 60 + ss;
		return final;
	}

	function goSpinner (element, parent, hidden, typesOfTime) {
		if (parent) {
			element.spinner({
				spin: function (event, ui) {
					if (ui.value >= 60) {
						$(this).spinner('value', ui.value - 60);
						parent.spinner('stepUp');
						return false;
					} else if (ui.value < 0) {
						$(this).spinner('value', ui.value + 60);
						parent.spinner('stepDown');
						return false;
					}
				},
				change: function (event, ui) {
					seconds = convertToSeconds(typesOfTime[2], typesOfTime[1], typesOfTime[0]);
					hidden.val(seconds);
				}
			});
		} else {
			element.spinner({
				min: 0,
				change: function (event, ui) {
					seconds = convertToSeconds(typesOfTime[2], typesOfTime[1], typesOfTime[0]);
					hidden.val(seconds);
				}
			});
		}
	}

	function spinnerYVAAT (typesOfTime, hidden) {
		for (index in typesOfTime) {
			parent = (index != 2) ? typesOfTime[parseFloat(index) + 1] : false;
			goSpinner(typesOfTime[index], parent, hidden, typesOfTime);
		}
	}

	spinnerYVAAT(
		[
			$('#start_time_seconds'),
			$('#start_time_minutes'),
			$('#start_time_hours')
		],
		$('#youtube_video_annotation_template_start_time')
	);

	spinnerYVAAT(
		[
			$('#end_time_seconds'),
			$('#end_time_minutes'),
			$('#end_time_hours')
		],
		$('#youtube_video_annotation_template_end_time')
	);

	spinnerYVAAT(
		[
			$('#link_start_time_seconds'),
			$('#link_start_time_minutes'),
			$('#link_start_time_hours')
		],
		$('#youtube_video_annotation_template_link_start_time')
	);

	function setTimeFromSeconds (hidden_field, hours_element, minutes_element, seconds_element) {
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

	setTimeFromSeconds($('#youtube_video_annotation_template_start_time'), $('#start_time_hours'), $('#start_time_minutes'), $('#start_time_seconds'));
	setTimeFromSeconds($('#youtube_video_annotation_template_end_time'), $('#end_time_hours'), $('#end_time_minutes'), $('#end_time_seconds'));
	setTimeFromSeconds($('#youtube_video_annotation_template_link_start_time'), $('#link_start_time_hours'), $('#link_start_time_minutes'), $('#link_start_time_seconds'));
}
