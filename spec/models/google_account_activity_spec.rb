require 'rails_helper'

RSpec.describe GoogleAccountActivity, type: :model do
  let(:google_account_activity) { GoogleAccountActivity.new }

  describe '.attributes' do
    %w(alternate_email default_text_style conversation_view stars chat_notifications
    mail_notifications contacts inbox_type inbox_categories importance_markers filtered_email
    chat_status chat_auto_add_contacts chat_voice chat_video chat_sounds_status chat_emoticons_status
    theme account_grant_access keyboard_shortcuts button_labels font_signature personal_level_indicators
    snippets vacation_responder import_mail import_contacts send_mail_as other_mail_check filters
    forwarding pop_settings imap_settings labs offline gv_outbound_voice_calling gv_call_forwarding_to_chat
    gv_work_number gv_number_to_forward gv_voice_mail_greeting gv_recorded_name gv_voice_mail_notifications
    gv_text_forwarding gv_voicemail_pin gv_voicemail_transcripts profile_photo open_emails delete_emails
    background change_spam_settings password password_recovery_options mark_as_read email_signature
    archive_email_activity phone recovery_email first_name last_name locality region country birth_date
    secret_question secret_answer calendar_events to_do_list account_security_settings recovery_attempt
    recovery_answer recovery_answer_date alternate_email_start default_text_style_start conversation_view_start
    stars_start chat_notifications_start mail_notifications_start contacts_start inbox_type_start
    inbox_categories_start importance_markers_start filtered_email_start chat_status_start
    chat_auto_add_contacts_start chat_voice_start chat_video_start chat_sounds_status_start
    chat_emoticons_status_start theme_start account_grant_access_start keyboard_shortcuts_start
    button_labels_start font_signature_start personal_level_indicators_start snippets_start
    vacation_responder_start import_mail_start import_contacts_start send_mail_as_start
    other_mail_check_start filters_start forwarding_start pop_settings_start imap_settings_start
    labs_start offline_start gv_outbound_voice_calling_start gv_call_forwarding_to_chat_start
    gv_work_number_start gv_number_to_forward_start gv_voice_mail_greeting_start gv_recorded_name_start
    gv_voice_mail_notifications_start gv_text_forwarding_start gv_voicemail_pin_start gv_voicemail_transcripts_start
    profile_photo_start open_emails_start delete_emails_start background_start change_spam_settings_start
    password_start password_recovery_options_start mark_as_read_start email_signature_start archive_email_activity_start
    phone_start recovery_email_start secret_question_start secret_answer_start calendar_events_start
    to_do_list_start account_security_settings_start youtube_personal_channel_start search_start watching_videos_start
    check_status_start recovery_attempt_start last_success_sign_in activity_start activity_end activity_end_crash
    recovery_attempt_crash verification_code_success_attempt last_recovery_email_inbox_mail_date recovery_success_date
    youtube_business_channel youtube_business_channel_start verify_youtube_business_channel
		verify_youtube_business_channel_start fill_youtube_business_channel_start fill_youtube_business_channel
		assign_recovery_phone_start assign_recovery_phone youtube_video_annotation_add youtube_video_annotation_add_start
		youtube_video_card_add youtube_video_card_add_start adwords_campaign_add adwords_campaign_add_start adwords_campaign_group_add
		adwords_campaign_group_add_start call_to_action_overlay_add call_to_action_overlay_add_start total_online_time
		start_online_at today_online_time youtube_video_info youtube_video_info_start youtube_website_associate youtube_website_associate_start google_plus_video_add google_plus_video_add_start).each do |a|
      it(a) { expect(google_account_activity).to respond_to(a) }
    end
  end
end