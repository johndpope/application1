stripped_url = document.location.toString().split("#")
if (stripped_url.length > 1) {
	$('#aae_templates_tab').trigger('click')
}

$('#source_video_subject_title_components_csv').select2({
	multiple: true,
	data: [],
	width: '100%',
	createSearchChoice: function (term, data) { return { id: term, text: term }; },
	initSelection: function (element, callback) {
		var values = $.map($(element).val().split(/\s*,\s*/), function (v) {
			return { id: v, text: v };
		});
		callback(values);
	}
});

$("#source_video_subject_title_components_csv_count").text($('#source_video_subject_title_components_csv').val().split(",").filter(Boolean).length);

$('#source_video_subject_title_components_csv').on('change', function(){
	$("#source_video_subject_title_components_csv_count").text($(this).val().split(",").filter(Boolean).length);
});

var colors = ["primary"];

function colorTags(){
	var tags = $('div#tag_list_block .tag');
	for(var i = 0; i < tags.length; i++){
		tags[i].className = "tag label label-tags label-" + colors[i % (colors.length)];
	}
}

function countKeywords(){
	tag_list_count = 0;
	var tag_list_block = $("#tag_list_block");
	var tag_list_block_input = $("#tag_list_block div.bootstrap-tagsinput");
	var tag_list = $("#source_video_tag_list").val();
	var tag_list_array = tag_list.split(",").filter(Boolean);
	tag_list_count = tag_list_array.length;
	$("#tag_list_count").text(tag_list_count);
}

$("#source_video_tag_list").tagsinput();
$(".bootstrap-tagsinput input").css('width', '');
$("#source_video_tag_list").on("change", function(){
	countKeywords();
	colorTags();
});
countKeywords();
colorTags();

// Counter characters
function calc_one (text_area) {
	text_area.closest('.form-group').find('.calc-one').text(text_area.val().length);
}

$('fieldset textarea').each(function () {
	calc_one($(this));
});

$(document).on('keyup', 'fieldset textarea', function () {
	calc_one($(this));
});

$(document).on('change', 'fieldset textarea', function () {
  calc_one($(this));
});

$(document).on('change', '.description-name-select', function () {
	text_input = $(this).closest('fieldset').find('textarea');
	text_input_limit = $('option:selected', $(this)).attr('data-text-type-limit');
	text_input_value = text_input.val();
	if (text_input_limit != undefined) {
		text_input.val(text_input_value.slice(0,text_input_limit));
		text_input.attr('maxlength', text_input_limit);
		text_input.attr('placeholder', 'Enter text (character limit: ' + text_input_limit + ')');
		text_input.trigger('change');
		if (text_input_value.length > text_input_limit){
			alert("Text string will be truncated!");
			text_input.effect('highlight', { color: 'red' }, 3000);
			text_input.trigger('keyup');
		}
	} else {
		text_input.val('');
		text_input.removeAttr('maxlength');
		text_input.attr('placeholder', 'Enter text');
		text_input.trigger('keyup');
	}
});
