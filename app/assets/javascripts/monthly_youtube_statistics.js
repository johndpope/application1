$(function () {
	$(document).on('ready page:load', function () {
		$.getScript("https://www.google.com/jsapi",function () {
			var cur_date = new Date();
			var year = $('#year').val();
			var month = $('#month').val();

			console.log(google);
			google.load('visualization', '1.0', {'packages':['corechart']});
			/*
				$.getJSON('/statistics/youtube_videos/uploads/' + (year != 'undefined' ? year : cur_date.getFullYear()) + '/' + (month != 'undefined' ? month : (cur_date.getMonth() + 1)),function (response) {
					drawChart($.parseJSON(response['statistics']));
				});
			*/
		});

		function drawChart (statistics) {
			var chart_data = [['x','Uploaded Videos']];
			$.each(statistics.points,function (index,value) {
				chart_data.push([value.day,value.count]);
			});

			var data = google.visualization.arrayToDataTable(chart_data);

			new google.visualization.LineChart(document.getElementById('video_uploads_chart')).draw(data, {
				curveType: 'function',
				width: 900,
				height: 400,
				vAxis: { maxValue: statistics.max_count },
				pointSize: 4,
				title: 'Upload statistics for ' + statistics.period + '. Total videos: ' + statistics.total_count
			});
		}
	});
});
