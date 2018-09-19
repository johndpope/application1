$(function () {
    function colorTags() {
        var tags = $('div#phrases_block .tag');
        for (var i = 0; i < tags.length; i++) {
            tags[i].className = 'tag label label-' + colors[i % (colors.length)];
        }
    }

    function countPhrases() {
        phrases_count = 0;
        var phrases_block = $('#phrases_block');
        var phrases_block_input = $('#phrases_block div.bootstrap-tagsinput');
        var phrases = $('#watching_video_category_phrases').val();

        if (phrases != '') {
            var phrases_array = phrases.split(',');
            phrases_count = phrases_array.length;
        }

        $('#phrases_label').text('Phrases: ' + phrases_count);
    }

    var colors = ['primary', 'success', 'info', 'warning', 'danger', 'default'];

    if (isForm('watching_video_category', true, true)) {
        $(document).ready(function() {
    		countPhrases();
    		//colorTags();

    		$('#watching_video_category_phrases').tagsinput();
    		$('.bootstrap-tagsinput input').css('width', '100%');
    	});

    	$('#watching_video_category_phrases').on('change', function() {
    		countPhrases();
    		//colorTags();
    	});
    }
});
