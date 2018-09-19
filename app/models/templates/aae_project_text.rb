class Templates::AaeProjectText < ActiveRecord::Base
	include Reversible
	belongs_to :aae_project, foreign_key: :aae_project_id, class_name: 'Templates::AaeProject'

	validates :name, presence: true, allow_blank: false
	validates :value, presence: true, allow_blank: false
	validates :aae_project_id, presence: true, allow_blank: false

	PROJECT_TYPES = Templates::AaeProject::VIDEO_TYPE.merge({transition: 8, general: 9})

	TEXT_TYPES = {client: 11, location: 12, state: 13, web_site: 14, phone: 15,
		video_subject: 16, facebook: 17, twitter: 18, youtube: 19,google_plus: 1001, instagram: 1002, linkedin: 1003, pinterest: 1004,
		intro_text: 21, intro_tagline: 22,
		bridge_to_sub_tagline: 31, bridge_to_sub_text: 32,
		sum_points_point_text: 41,
		collage_call_to_action: 51, collage_quote: 52,
		likes_and_views_tagline: 61,
		ending_tagline: 71,
		social_networks_call_to_action: 81,
		credits_link: 95, credits_client_disclaimer: 96,
		transition_client_quote: 101,
		call_to_action_text: 201,
		subscription_notification_text: 301}

	PROJECT_TEXT_TYPES = {
		bridge_to_subject: [:bridge_to_sub_text, :bridge_to_sub_tagline],
		call_to_action: [:call_to_action_text],
		collage: [:collage_quote, :collage_call_to_action],
		ending: [:ending_tagline],
		general: [:client],
		introduction: [:intro_text, :intro_tagline],
		likes_and_views: [:likes_and_views_tagline],
		summary_points: [:sum_points_point_text],
		social_networks: [:social_networks_call_to_action],
		transition: [:transition_client_quote],
		credits: [:credits_link, :credits_client_disclaimer],
		subscription: [:subscription_notification_text]
	}

	TEXT_GROUPES = {
		bridge_to_subject: [:bridge_to_sub_text, :bridge_to_sub_tagline],
		call_to_action: [:call_to_action_text],
		collage: [:collage_quote, :collage_call_to_action],
		credits: [:credits_link, :credits_client_disclaimer],
		ending: [:ending_tagline],
		general: [:client, :video_subject, :location, :state, :web_site, :phone,
			:facebook, :twitter, :youtube, :google_plus, :instagram, :linkedin, :pinterest],
		introduction: [:intro_text, :intro_tagline],
		likes_and_views: [:likes_and_views_tagline],
		summary_points: [:sum_points_point_text],
		social_networks: [:social_networks_call_to_action],
		transition: [:transition_client_quote],
		subscription: [:subscription_notification_text]
	}

  TEXT_GROUPES_LIMITS = {
    bridge_to_subject: {bridge_to_sub_text: 50, bridge_to_sub_tagline: 40},
    call_to_action: {call_to_action_text: 50},
    collage: {collage_quote: 80, collage_call_to_action: 30},
    credits: {credits_link: 80, credits_client_disclaimer: 1300},
    ending: {ending_tagline: 70},
    general: {client: 50, video_subject: 100, location: 50, state: 50, web_site: 50, phone: 50,
      facebook: 100, twitter: 100, youtube: 100, google_plus: 100, instagram: 100, linkedin: 100, pinterest: 100},
    introduction: {intro_text: 30, intro_tagline: 40},
    likes_and_views: {likes_and_views_tagline: 50},
    summary_points: {sum_points_point_text: 100},
    social_networks: {social_networks_call_to_action: 50},
    transition: {transition_client_quote: 70},
		subscription:{subscription_notification_text: 100}
  }

	extend Enumerize
	enumerize :text_type, in: TEXT_TYPES, scope: true

	default_scope{order(id: :desc)}

	before_save :on_before_save

	def presents_in_project!
		self.presents_in_project = presents_in_project?
	end

	def presents_in_project?
		xml_doc = Nokogiri::XML(self.xml)
		xml_doc.at("string:contains(#{self.name})")
	end

	def self.encode_string(s)
		unicodes_to_replace = {"22" => "201d", "27" => "2019"}
		unicodes_to_escape = %w(28 29 5c)
		(s.to_s.each_char.map do |c|
			unicode = c.ord.to_s(16)
			if unicodes_to_replace.keys.include? unicode
				unicodes_to_replace[unicode]
			else
				if unicodes_to_escape.include? unicode
					"005c#{unicode}"
				else
					("%4s" % unicode).gsub(' ', '0')
				end
			end
		end).join
	end

	def self.decode_string(s)

	end

	private
		def on_before_save
			ActiveRecord::Base.transaction do
				if(name_changed? || value_changed? || is_static_changed?)
					#remove existing delayed jobs
					Delayed::Job.
						where("(queue = ? OR queue = ?) AND handler like ?",
							DelayedJobQueue::TEMPLATES_AAE_PROJECT_VALIDATE_TEXTS,
							DelayedJobQueue::TEMPLATES_AAE_PROJECT_VALIDATE_IMAGES,
							"%aae_project_id: '#{self.aae_project_id}'%").each do |dj|
								dj.delete
					end

					#delayed job for texts validation
					Delayed::Job.enqueue Templates::AaeProjects::ValidateTextLayersJob.new(self.aae_project_id.to_s),
						queue: DelayedJobQueue::TEMPLATES_AAE_PROJECT_VALIDATE_TEXTS
					#delayed jobs for images validation
					Delayed::Job.enqueue Templates::AaeProjects::ValidateImagesJob.new(self.aae_project_id.to_s),
						queue: DelayedJobQueue::TEMPLATES_AAE_PROJECT_VALIDATE_IMAGES

					self.aae_project.content_lock = true
					self.aae_project.save!
				end
			end
		end

end
