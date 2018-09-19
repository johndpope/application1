class YoutubeSetup < ActiveRecord::Base
	include Paragraphable
	include RegexPatterns
	include CSVAccessor
	include Referable
	include Reversible

	VIDEO_DESCRIPTION_LIMIT = YoutubeVideo::VIDEO_DESCRIPTION_LIMIT
	CHANNEL_DESCRIPTION_LIMIT = YoutubeChannel::CHANNEL_DESCRIPTION_LIMIT

  MINIMUM_SHORT_DESCRIPTIONS = 5
  MINIMUM_LONG_DESCRIPTIONS = 5

  SHORT_DESCRIPTION_CHARACTERS_LIMIT = 150
  LONG_DESCRIPTION_CHARACTERS_LIMIT = 500

	belongs_to :email_accounts_setup
  validates_uniqueness_of :email_accounts_setup_id
	belongs_to :client
	has_many :youtube_video_annotation_templates
	accepts_nested_attributes_for :youtube_video_annotation_templates, allow_destroy: true
	has_many :youtube_video_card_templates
	accepts_nested_attributes_for :youtube_video_card_templates, allow_destroy: true
  has_many :wordings, as: :resource

  serialize :"wordings", Array
  has_csv_accessors_for "wordings"

  has_references_for :wordings
  accepts_nested_attributes_for :wordings, allow_destroy: true, reject_if: ->(attributes) { attributes[:source].blank? && attributes[:name].blank? }

	%w(business personal).each do | i |
		serialize :"#{i}_channel_entity", Array
		serialize :"#{i}_channel_subject", Array
		serialize :"#{i}_channel_descriptor", Array
		has_csv_accessors_for "#{i}_channel_entity"
		has_csv_accessors_for "#{i}_channel_subject"
		has_csv_accessors_for "#{i}_channel_descriptor"

		has_references_for :"#{i}_channel_art"
		accepts_nested_attributes_for :"#{i}_channel_art_references", allow_destroy: true, reject_if: ->(attributes) { attributes[:url].blank? }

		validates "#{i}_inquiries_email".to_sym, format: { with: valid_email_pattern, allow_blank: true }

		%w(channel video).each do | j |
      acts_as_taggable_on :"other_#{i}_#{j}_tags"
			%w(entity subject descriptor).each do | k |
				serialize :"#{i}_#{j}_#{k}", Array
				has_csv_accessors_for :"#{i}_#{j}_#{k}"
        validates :"#{i}_#{j}_#{k}", presence: true if i == 'business' && k != 'subject' && k != 'descriptor'
			end

			%w(description tags).each do | k |
				association = [i, j, k].join('_')
				has_paragraphs_for association.to_sym
				accepts_nested_attributes_for "#{association}_paragraphs".to_sym, allow_destroy: true, reject_if: ->(attributes) { attributes[:title].blank? && attributes[:body].blank? }

				validates association.to_sym, length: { maximum: const_get("#{j.upcase}_DESCRIPTION_LIMIT") } if k == 'description'
			end
		end
	end
  validates :business_channel_title_patterns, :business_video_title_patterns, presence: true

	validates :email_accounts_setup, presence: true
	validates :client, presence: true
	# validate :ensure_tags_presence
	validates :adwords_account_name, :adwords_campaign_name, :adwords_campaign_type, :adwords_campaign_languages, :adwords_campaign_start_date, :adwords_campaign_group_name, :adwords_campaign_group_video_ad_format, :adwords_campaign_group_ad_name, :call_to_action_overlay_headline, :call_to_action_overlay_display_url, :call_to_action_overlay_destination_url, presence: true, if: :use_call_to_action_overlay?

	validates :adwords_campaign_group_headline, :adwords_campaign_group_description_1, :adwords_campaign_group_description_2, presence: true, if: :is_in_display_ad_format?
	validates :adwords_campaign_group_display_url, :adwords_campaign_group_final_url, presence: true, if: :is_in_stream_ad_format?

  validate :descriptions_presence

	before_save :clean_up_protected_words

	extend Enumerize
	enumerize :adwords_campaign_type, in: AdwordsCampaign::TYPES
	enumerize :adwords_campaign_subtype, in: AdwordsCampaign::SUBTYPES
	enumerize :adwords_campaign_group_video_ad_format, in: AdwordsCampaignGroup::VIDEO_AD_FORMATS

  def description_wording(name)
    self.id.present? ? Wording.where("resource_id = ? AND resource_type = 'YoutubeSetup' AND name = ?", self.id, name).order("random()").first : nil
  end

  def destroy_description_wordings(name)
    Wording.where("resource_id = ? AND resource_type = 'YoutubeSetup' AND name = ?", self.id, name).destroy_all
  end

	def use_call_to_action_overlay?
		use_call_to_action_overlay
	end

	def is_in_display_ad_format?
		self.adwords_campaign_group_video_ad_format == YoutubeSetup.adwords_campaign_group_video_ad_format.find_value('In-display ad') && use_call_to_action_overlay?
	end

	def is_in_stream_ad_format?
		self.adwords_campaign_group_video_ad_format == YoutubeSetup.adwords_campaign_group_video_ad_format.find_value('In-stream ad') && use_call_to_action_overlay?
	end

	def clean_up_protected_words
		self.protected_words = self.protected_words.to_s.split(",").collect(&:strip).uniq.join(",")
	end

	private
    def descriptions_presence
      short_descriptions_size = self.wordings.to_a.select {|w| w.name == 'short_description'}.size
      long_descriptions_size = self.wordings.to_a.select {|w| w.name == 'long_description'}.size
      minimum_short_descriptions = Setting.get_value_by_name("YoutubeSetup::MINIMUM_SHORT_DESCRIPTIONS").to_i
      minimum_long_descriptions = Setting.get_value_by_name("YoutubeSetup::MINIMUM_LONG_DESCRIPTIONS").to_i
      if short_descriptions_size > 0 && short_descriptions_size < minimum_short_descriptions
        errors.add(:wordings, "Short descriptions are less than #{minimum_short_descriptions}")
      end
      if long_descriptions_size > 0 && long_descriptions_size < minimum_long_descriptions
        errors.add(:wordings, "Long descriptions are less than #{minimum_long_descriptions}")
      end
    end

		def ensure_tags_presence
			%w(business personal).each do | i |
				%w(channel video).each do | j |
					errors.add("#{i}_#{j}_tags", 'can\'t be blank') if send("#{i}_#{j}_tags_paragraphs").all?(&:marked_for_destruction?)
				end
			end
		end
end
