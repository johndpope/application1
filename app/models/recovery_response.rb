require "ordinalize_full/integer"
require 'action_view'
require 'action_view/helpers'
include ActionView::Helpers::DateHelper

class RecoveryResponse < ActiveRecord::Base
	#Gmail response limit 1000
	GMAIL_RESPONSE_LIMIT = 995
  YOUTUBE_RESPONSE_LIMIT = 995
	# chunk_types:
	# 'recovery_ending', 'recovery_intro2', 'recovery_intro1', 'recovery_gmail_subject', 'recovery_youtube_subject', 'recovery_twitter_subject', 'recovery_facebook_subject', 'recovery_bridge1', 'recovery_google_plus_subject', 'recovery_bridge2'

  SERVICE_NAMES = {
    'gmail' => ['Gmail', 'Google'],
    'youtube' => ['Youtube', 'YouTube']
  }

	POLICY_NAMES = {
		'youtube' => ['Community Guidelines'],
		'google_plus' => ['Google+ Policy', 'Google Plus Policy'],
		'twitter' => ['Twitter Terms of Services', 'Twitter Rules'],
		'facebook' => ['Terms of Service', 'Community Standards', 'Statements', 'Terms', 'SRR', 'Services', 'Statement of Rights and Responsibilities', 'Facebook Services'],
		'gmail' => ['Google Terms of Service', 'Terms of Service', 'product-specific policies', 'Program Policies', 'Gmail Program Policies']
	}

  GOOGLE_POLICY_NAMES_BY_EMAIL_TYPE = {
    [12,18,19,72,73] => [['recovery_google_policies_subject'], ['Google Policies']],
    [1,16] => [['recovery_google_terms_of_services_subject'], ['Google Terms of Services']],
    [3,5,7,9,22] => [['recovery_google_terms_and_policies_subject'], ['Terms of Services']],
    [6,8,10,11,13,15,20,21,23,24,25,28,30,54,55,56] => [['recovery_google_policies_subject', 'recovery_google_terms_of_services_subject', 'recovery_google_terms_and_policies_subject'], ['Google Policies', 'Google Terms of Services', 'Terms of Services']],
    [14,17,57] => [['recovery_someone_has_your_password_subject'], ['Google Policies']],
    [2] => [['recovery_pending_appeal_subject'], ['Google Policies']]
  }

  YOUTUBE_POLICY_NAMES_BY_EMAIL_TYPE = {
    [32,33,38] => [['recovery_youtube_terms_of_services_subject', 'recovery_youtube_community_guidelines_subject'], ['Terms of Services', 'Community guidelines']],
    [39] => [['recovery_youtube_community_guidelines_subject'], ['Community guidelines']],
    [31] => [['recovery_pending_appeal_subject'], ['Terms of Services']]
  }

  POLICY_NAMES_BY_EMAIL_TYPE = GOOGLE_POLICY_NAMES_BY_EMAIL_TYPE.merge(YOUTUBE_POLICY_NAMES_BY_EMAIL_TYPE)

	belongs_to :resource, polymorphic: true
	validates :response, presence: true
	validates :resource, presence: true

	def self.generate_response_text(service_name, attempts_size, text_limit, recovery_inbox_email = nil)
    s_name = SERVICE_NAMES[service_name].try(:shuffle).try(:first) || service_name
		intro1 = TextChunk.where(chunk_type: 'recovery_intro1').order('random()').first.try(:value).try(:to_s).gsub('<ins>', s_name)
		intro2 = ''
		if attempts_size > 0 && attempts_size <= (7..10).to_a.shuffle.first
      attempt = attempts_size + 1
			intro2 = TextChunk.where(chunk_type: 'recovery_intro2').order('random()').first.try(:value).try(:to_s).gsub('<num>', [attempt.ordinalize_full, attempt.ordinalize].shuffle.first).gsub('<ins>', attempt.to_s)
		end
    policy_name = nil
    subject_name = nil
    policy = nil
    recovery_inbox_email_date = nil
    if recovery_inbox_email.present? && recovery_inbox_email.email_type.present?
      RecoveryResponse::POLICY_NAMES_BY_EMAIL_TYPE.each do |key, value|
        if key.include?(recovery_inbox_email.email_type.value)
          policy = value
          recovery_inbox_email_date = recovery_inbox_email.date
          break
        end
      end
    end
    unless policy.present?
      policy = case service_name
      when 'gmail'
        RecoveryResponse::GOOGLE_POLICY_NAMES_BY_EMAIL_TYPE[RecoveryResponse::GOOGLE_POLICY_NAMES_BY_EMAIL_TYPE.keys.shuffle.first]
      when 'youtube'
        RecoveryResponse::YOUTUBE_POLICY_NAMES_BY_EMAIL_TYPE[RecoveryResponse::YOUTUBE_POLICY_NAMES_BY_EMAIL_TYPE.keys.shuffle.first]
      end
    end
    if policy.present?
      index = (0..(policy.first.size - 1)).to_a.shuffle.first
      policy_name = policy.second[index]
      subject_name = policy.first[index]
    end

    intro3 = nil

    if recovery_inbox_email_date.present?
      dates = ["#{time_ago_in_words(recovery_inbox_email_date)} ago",
        recovery_inbox_email_date.strftime("on %m/%d/%Y"),
        recovery_inbox_email_date.strftime("on %b/%d/%Y"),
        recovery_inbox_email_date.strftime("on %b/%d/%y"),
        recovery_inbox_email_date.strftime("on %b-%d-%Y"),
        recovery_inbox_email_date.strftime("on %b-%d-%y"),
        recovery_inbox_email_date.strftime("on %m/%d/%y"),
        recovery_inbox_email_date.strftime("on %m-%d-%Y"),
        recovery_inbox_email_date.strftime("on %m-%d-%y"),
        recovery_inbox_email_date.strftime("on %b #{recovery_inbox_email_date.day.ordinalize}"),
        recovery_inbox_email_date.strftime("on %B %d, %Y"),
        recovery_inbox_email_date.strftime("on the #{recovery_inbox_email_date.day.ordinalize} of %B"),
        recovery_inbox_email_date.strftime("on %b %d, %Y"),
        recovery_inbox_email_date.strftime("on %b %d, %y"),
        recovery_inbox_email_date.strftime("on the #{recovery_inbox_email_date.day.ordinalize} of %B-%y"),
        recovery_inbox_email_date.strftime("on the #{recovery_inbox_email_date.day.ordinalize} of %B-%Y"),
        recovery_inbox_email_date.strftime("on the #{recovery_inbox_email_date.day.ordinalize} of %B, %y"),
        recovery_inbox_email_date.strftime("on the #{recovery_inbox_email_date.day.ordinalize} of %B, %Y")]
      intro3 = TextChunk.where(chunk_type: 'recovery_intro3').order('random()').first.try(:value).to_s.gsub('<ins>', dates.shuffle.first)
      intro3 = intro3.slice(0,1).to_s.capitalize + intro3.slice(1..-1).to_s
    end
    policy_name = POLICY_NAMES[service_name].shuffle.first unless policy_name.present?
    subject_name = "recovery_#{service_name}_subject" unless subject_name.present? && TextChunk.where(chunk_type: subject_name).present?
		bridge1 = TextChunk.where(chunk_type: 'recovery_bridge1').order('random()').first.try(:value).try(:to_s).gsub('<ins>', policy_name)
		subject1_chunk = TextChunk.where(chunk_type: subject_name).order('random()').first
		subject1 = subject1_chunk.try(:value).try(:to_s)
		bridge2 = ''
		subject2 = ''

		if [false, true].shuffle.first
			bridge2 = TextChunk.where("chunk_type = 'recovery_bridge2'").order('random()').first.try(:value).try(:to_s)
			subject2 = TextChunk.where("chunk_type = ? AND id <> ?", subject_name, subject1_chunk.try(:id)).order('random()').first.try(:value).try(:to_s)
		end

		ending = TextChunk.where(chunk_type: 'recovery_ending').order('random()').first.try(:value).try(:to_s)

    if recovery_inbox_email.present? && recovery_inbox_email.email_type.present? && [14,17,57,2].include?(recovery_inbox_email.email_type.value)
      bridge1 = ''
      bridge2 = ''
  		subject2 = ''
    end

    if recovery_inbox_email.present? && recovery_inbox_email.email_type.present? && [31].include?(recovery_inbox_email.email_type.value)
      intro2 = ''
      bridge1 = ''
      bridge2 = TextChunk.where(chunk_type: 'recovery_bridge1').order('random()').first.try(:value).try(:to_s).gsub('<ins>', policy_name)
      subject_name = "recovery_youtube_subject"
      subject2_chunk = TextChunk.where(chunk_type: subject_name).order('random()').first
  		subject2 = subject2_chunk.try(:value).try(:to_s)
    end

		if [intro1, intro2, intro3, bridge1, subject1, bridge2, subject2, ending].compact.reject(&:empty?).join(' ').size >= text_limit
			bridge2 = ''
			subject2 = ''
		elsif bridge2.present? && subject2.present? && ![31].include?(recovery_inbox_email.try(:email_type).try(:value))
			#removes last dot at the end
			subject1 = subject1.gsub(/\.$/, '')
		end
		final_text = [intro1, intro2, intro3, bridge1, subject1, bridge2, subject2, ending].compact.reject(&:empty?).join(' ').gsub(" ,", ",").gsub(" ;", ";")
		#truncates sentense not by characters, but by the words using characters limit
		final_text = final_text[0..text_limit].gsub(/\s\w+$/,'') if final_text.size > text_limit
		final_text
	end
end
