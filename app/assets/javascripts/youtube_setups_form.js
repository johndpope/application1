//= require 'jquery_nested_form'
//= require 'youtube_setups_form_yvt'
//= require 'youtube_setups_form_annotations'
//= require 'youtube_setups_form_cards'

var ready = function () {
	var types = ['business', 'personal'];
	var targets = ['channel', 'video'];
	var fields = ['description', 'tags'];
	var paragraph_groups = [];

	// Hide 'swap' links after the sections that go last
	for (i in types) {
		for (j in targets) {
			for (k in fields) {
				var id = [types[i], targets[j], fields[k]].join('_');
				$('#' + id + ' .fields').last().find('a.swap').hide();
				paragraph_groups.push(id + '_paragraphs');
			}
		}
	}

	// Adjust cursor focus & Swap links placement when new paragraph is entered
	var paragraph_added_events = 'nested:fieldAdded:' + paragraph_groups.join(' ');

	$(document).on(paragraph_added_events, function (event) {
		field = $(event.field);
		positions = field.parent().find('.fields:visible .paragraph_position').map(function () {
			return parseInt($(this).val() || '0')
		});
		max = Math.max.apply(null, positions);
		field.find('.paragraph_position').val(max + 1);
		field.find('input[type="text"]').focus();
		field.find('a.swap').hide();
		field.prev(':visible').find('a.swap').show();
	});

	// Adjust cursor focus & Swap links placement when a paragraph gets removed
	var paragraph_removed_events = 'nested:fieldRemoved:' + paragraph_groups.join(' ');

	$(document).on(paragraph_removed_events, function (event) {
		$(event.field).parent().find('.fields:visible').last().find('a.swap').hide();
	});

	// Perform paragraph content swapping
	$('body').on('click', 'a.swap', function () {
		var fields1 = $(this).closest('.fields');
		var fields2 = fields1.next();
		var title1 = fields1.find('input[type=text]');
		var title2 = fields2.find('input[type=text]');
		var body1 = fields1.find('textarea');
		var body2 = fields2.find('textarea');
		var buffer = title1.val();
		title1.val(title2.val());
		title2.val(buffer);
		buffer = body1.val();
		body1.val(body2.val());
		body2.val(buffer);
	});

	// Apply select2 to fields with multiple values
	var selectors = [
		'#youtube_setup_business_channel_entity_csv',
		'#youtube_setup_personal_channel_entity_csv',
		'#youtube_setup_business_channel_subject_csv',
		'#youtube_setup_personal_channel_subject_csv',
		'#youtube_setup_business_channel_descriptor_csv',
		'#youtube_setup_personal_channel_descriptor_csv',
		'#youtube_setup_business_video_entity_csv',
		'#youtube_setup_personal_video_entity_csv',
		'#youtube_setup_business_video_subject_csv',
		'#youtube_setup_personal_video_subject_csv',
		'#youtube_setup_business_video_descriptor_csv',
		'#youtube_setup_personal_video_descriptor_csv',
		'#youtube_setup_adwords_account_name',
		'#youtube_setup_adwords_campaign_name',
		'#youtube_setup_adwords_campaign_group_name',
		'#youtube_setup_adwords_campaign_group_display_url',
		'#youtube_setup_adwords_campaign_group_final_url',
		'#youtube_setup_adwords_campaign_group_headline',
		'#youtube_setup_adwords_campaign_group_description_1',
		'#youtube_setup_adwords_campaign_group_description_2',
		'#youtube_setup_adwords_campaign_group_ad_name',
		'#youtube_setup_call_to_action_overlay_headline',
		'#youtube_setup_call_to_action_overlay_display_url',
		'#youtube_setup_call_to_action_overlay_destination_url'
	].join(', ');

	$(selectors).select2({
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

  $(".subject_title_components").select2({
		multiple: true,
    disabled: true,
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

  $(".subject_title_components").css("cursor", "not-allowed").attr("readonly", "true");

  $(selectors).each(function(){
    var target_id = $(this).attr("id");
    $("#" + target_id + "_count").text($(this).val().split(",").filter(Boolean).length);
  })

  $(selectors).on('change', function(){
    var target_id = $(this).attr("id");
    $("#" + target_id + "_count").text($(this).val().split(",").filter(Boolean).length);
  });

  var title_patterns_selectors = [
		'#youtube_setup_business_channel_title_patterns',
		'#youtube_setup_business_video_title_patterns',
		'#youtube_setup_personal_channel_title_patterns',
		'#youtube_setup_personal_video_title_patterns'
  ]

  $(title_patterns_selectors).select2()

	$('#youtube_setup_email_accounts_setup_id').select2();
  $('#youtube_setup_rotate_content_frequency').select2({allowClear: true});

	isForm('youtube_setup', true, true);

	$('#use_youtube_channel_art_text_div ins, #use_youtube_channel_art_text_div label').on('click', function () {
		$('#youtube_setup_youtube_channel_art_text').val('');
		if ($('#use_youtube_channel_art_text_div .icheckbox_minimal-blue').hasClass('checked')) {
			$('#youtube_channel_art_text_block').show();
		} else {
			$('#youtube_channel_art_text_block').hide();
		}
	});

	$('#youtube_setup_adwords_campaign_languages').on('change', function () {
		var languages_values = $(this).val();
		if (languages_values != null && languages_values[0] == 'all-languages') $('#youtube_setup_adwords_campaign_languages').select2('val', ['all-languages']);
	});

	$('#youtube_setup_adwords_campaign_type').on('change', function () {
		($(this).val() == 5) ? $('#subtype_block').show() : $('#subtype_block').hide();
	});

  $('#youtube_setup_social_links_in_youtube_video_description').on('change', function () {
    var value = $('#youtube_setup_social_links_in_youtube_video_description').val();
    if (value < 0) $('#youtube_setup_social_links_in_youtube_video_description').val(0);
  });

	$('#youtube_setup_adwords_campaign_group_video_ad_format').on('change', function () {
		if ($(this).val() == 1) {
			$('#in_stream_ad_block').show();
			$('#in_display_ad_block').hide();
		} else {
			$('#in_stream_ad_block').hide();
			$('#in_display_ad_block').show();
		}
		$('#youtube_setup_adwords_campaign_group_display_url, #youtube_setup_adwords_campaign_group_final_url, #youtube_setup_adwords_campaign_group_headline, #youtube_setup_adwords_campaign_group_description_1, #youtube_setup_adwords_campaign_group_description_2').val('');
	});

	$('input[name="youtube_setup[use_call_to_action_overlay]"]').on('ifChanged', function (event) {
		use_block = $('#use_call_to_action_overlay_block');

		if (this.checked) {
			use_block.show();
			$('#youtube_setup_adwords_campaign_type').val('5').trigger('change');
			$('#youtube_setup_adwords_campaign_subtype').val('1').trigger('change');
			$('#youtube_setup_adwords_campaign_group_video_ad_format').val('2').trigger('change');
			$('#youtube_setup_adwords_campaign_networks_youtube_search, #youtube_setup_adwords_campaign_networks_youtube_videos, #youtube_setup_adwords_campaign_networks_include_video_partners, #youtube_setup_call_to_action_overlay_enabled_on_mobile').iCheck('check');
		} else {
			use_block.hide();
			use_block.find('input[type="text"], textarea').val('');
			use_block.find('.multi').select2('val', '');
		}
	});

	$('#youtube_setup_protected_words').tagsinput();

  var colors = ["primary"];

  function colorTags(selector){
    var tags = $("div#" + selector + "_block .tag");
    for(var i = 0; i < tags.length; i++){
      tags[i].className = "tag label label-tags label-" + colors[i % (colors.length)];
    }
  }

  function countKeywords(selector){
    tag_list_count = 0;
    var tag_list = $("#" + selector).val();
    var tag_list_array = tag_list.split(",").filter(Boolean);
    tag_list_count = tag_list_array.length;
    $("#" + selector + "_count").text(tag_list_count);
  }

  $(".tags-field").tagsinput();
  $(".bootstrap-tagsinput input").css('width', '');
  $(".tags-field").on("change", function(){
    countKeywords($(this).attr("id"));
    colorTags($(this).attr("id"));
  });

  $('.tags-field').each(function() {
    countKeywords($(this).attr("id"));
    colorTags($(this).attr("id"));
  });

  $('#business_channel_title_patterns_arrow_down').on('click', function(){
    $("#youtube_setup_business_channel_title_patterns").select2("open");
  });
  $('#personal_channel_title_patterns_arrow_down').on('click', function(){
    $("#youtube_setup_personal_channel_title_patterns").select2("open");
  });

  $('#business_video_title_patterns_arrow_down').on('click', function(){
    $("#youtube_setup_business_video_title_patterns").select2("open");
  });
  $('#personal_video_title_patterns_arrow_down').on('click', function(){
    $("#youtube_setup_personal_video_title_patterns").select2("open");
  });


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
}

$(document).ready(ready);
$(document).on('page:load', ready);
