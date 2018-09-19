function render_card () {
	$(document).on('change', '#youtube_video_card_template_card_type', function () {
		fields = $(document).find('#channel_type_fields');

		($(this).val() == 2) ? fields.show() : fields.hide();

		$(document).find('#youtube_video_card_template_custom_message').val('');
		$(document).find('#youtube_video_card_template_teaser_text').val('');
		$(document).find('#youtube_video_card_template_url').val('');
	});
};
