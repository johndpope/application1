$(function () {
	$('select').select2();
	$(document).ready(function () {
		isForm('adwords_campaign_group', true, true);
		$('.select2-container').addClass('form-control');
	});

	$('#adwords_campaign_group_video_ad_format').on("change", function () {
		if ($(this).val() == 1) {
			$('#in_stream_ad_block').show();
			$('#in_display_ad_block').hide();
		} else {
			$('#in_stream_ad_block').hide();
			$('#in_display_ad_block').show();
		}

		$('#adwords_campaign_group_display_url, #adwords_campaign_group_final_url, #adwords_campaign_group_headline, #adwords_campaign_group_description_1, #adwords_campaign_group_description_2').val('');
	});
});
