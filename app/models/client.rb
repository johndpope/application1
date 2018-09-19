class Client < ActiveRecord::Base
  include Reversible
	include CSVAccessor
	include Referable

	extend Enumerize

  belongs_to :industry
  belongs_to :parent, class_name: 'Client', foreign_key: :parent_id
  has_many :representatives, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :invoices
	has_many :source_videos, through: :products, dependent: :destroy
	has_many :client_landing_pages, dependent: :destroy
  has_many :contracts, dependent: :destroy
  has_many :email_accounts_setups, dependent: :destroy
  has_many :youtube_setups, dependent: :destroy
  has_many :aae_project_dynamic_texts, class_name: "Templates::AaeProjectDynamicText"
	has_many :wordings, as: :resource
	has_one :rendering_settings, class_name: 'ClientRenderingSettings'
	has_many :client_donors, dependent: :destroy
	has_many :donors, through: :client_donors, dependent: :destroy
	has_many :client_recipients
	has_many :recipients, through: :client_recipients
	has_many :client_donor_source_videos
	has_many :donor_videos, through: :client_donor_source_videos, source: :source_video, before_remove: :destroy_recipient_source_video
	has_many :recipient_videos, through: :client_donor_source_videos, source: :recipient_source_video
	has_one :blending_settings, class_name: 'ClientBlendingSettings'

	has_many :dealer_certifications
	has_many :certifying_manufacturers, through: :dealer_certifications, source: :manufacturer

	has_many :blended_videos, through: :source_videos

  has_many :dealers
  has_one :video_marketing_campaign_form, dependent: :destroy
  has_many :screenshots, as: :screenshotable, dependent: :destroy

  validates :name, :nickname, :tag_list, presence: true
  validates :website, :facebook_url, :google_plus_url, :linkedin_url, :pinterest_url, :instagram_url, :blog_url, :twitter_url, :youtube_url, url: { allow_blank: true, message: "This is not a valid URL. Valid URL starts with http:// or https://" }
  validate :descriptions_presence

  MINIMUM_SHORT_DESCRIPTIONS = 3
  MINIMUM_LONG_DESCRIPTIONS = 5

  PHONE_TYPES = {mobile: "m:", work: "w:", home: "h:", other: "o:"}

	BUSINESS_TYPES = {manufacturer: 1, dealer: 2}
	enumerize :business_type, in: BUSINESS_TYPES, scope: true

  acts_as_taggable
  acts_as_taggable_on :client_name_tags

	before_save :clean_up_protected_words
	after_create :create_rendering_settings

	serialize :"wordings", Array
	has_csv_accessors_for "wordings"

	has_references_for :wordings
	accepts_nested_attributes_for :wordings, allow_destroy: true, reject_if: ->(attributes) { attributes[:source].blank? && attributes[:name].blank? }
	accepts_nested_attributes_for :rendering_settings, allow_destroy: true
	accepts_nested_attributes_for :products, allow_destroy: true
	accepts_nested_attributes_for :client_donors, allow_destroy: true
	accepts_nested_attributes_for :client_recipients, allow_destroy: true
	accepts_nested_attributes_for :client_donor_source_videos, allow_destroy: true
	accepts_nested_attributes_for :aae_project_dynamic_texts, allow_destroy: true
	accepts_nested_attributes_for :dealer_certifications, allow_destroy: true
	accepts_nested_attributes_for :blending_settings, allow_destroy: true

	before_create :set_public_profile_uuid
	before_create do
		self.ignore_special_templates = true
	end
	before_save :before_save

  def descriptions_presence
    if self.wordings.to_a.select {|w| w.name == 'short_description'}.size < MINIMUM_SHORT_DESCRIPTIONS
      errors.add(:wordings, "Short descriptions are less than #{MINIMUM_SHORT_DESCRIPTIONS}")
    end
    if self.wordings.to_a.select {|w| w.name == 'long_description'}.size < MINIMUM_LONG_DESCRIPTIONS
      errors.add(:wordings, "Long descriptions are less than #{MINIMUM_LONG_DESCRIPTIONS}")
    end
  end

	%w(logo badge_logo).each do |l|
		attr_accessor l
		attr_accessor "remove_#{l}"
		attachment_options = {styles: {thumb: "150x150>"}}
		if l == 'badge_logo'
			attachment_options[:path] = Rails.configuration.paperclip_attachment_default_options[:path]
			attachment_options[:url] = Rails.configuration.paperclip_attachment_default_options[:url]
		end
	  has_attached_file l, attachment_options
	  validates_attachment l,
	    content_type: {content_type: ['image/png']},
	    size: {greater_than: 0.bytes, less_than: 2.megabytes}
	end

  def set_public_profile_uuid
    self.public_profile_uuid = SecureRandom.uuid
  end

  def phones
    (read_attribute(:phones) || []).map do |p|
      #p.gsub(/[^\d]/, '')
      p =~ /^\d{12}$/ ? "#{p[0..1]}(#{p[2..4]}) #{p[5..7]}-#{p[8..12]}" : p
    end
  end

  def phones_csv
    phones.try(:join, ', ')
  end

  def phones_csv=(values)
    self.phones = values.strip.split(/\s*,\s*/)
  end

  def full_name
    [ first_name, mid_name, last_name ].compact.join(' ')
  end

  def source_videos
    SourceVideo.where(product_id: products.pluck(:id))
  end

	def description_wording(name)
		self.id.present? ? Wording.where("resource_id = ? AND resource_type = 'Client' AND name = ?", self.id, name).order("random()").first : nil
	end

	def destroy_description_wordings(name)
		Wording.where("resource_id = ? AND resource_type = 'Client' AND name = ?", self.id, name).destroy_all
	end

	def clean_up_protected_words
		self.protected_words = self.protected_words.to_s.split(",").collect(&:strip).uniq.join(",")
	end

	def source_videos_available_for_distribution
		source_videos.
			where(ready_for_production: true).
			where("video_workflow_source_video_production_progress(id) < 100")
	end

	def recipients
		Client.joins(:client_donors).where("client_donors.donor_id = ?", self.id)
	end

	private
		def create_rendering_settings
			if self.rendering_settings.nil?
				ClientRenderingSettings.create! client_id: self.id, rendering_priority: 0, auto_approve_rendered_video_chunks: false
			end
		end

		def before_save
			%w(logo badge_logo).each do |l|
				self.send("#{l}=", nil) if self.send("remove_#{l}") == 'true'
			end
		end

		def destroy_recipient_source_video(donor_video)
			ActiveRecord::Base.transaction do
				if cdsv = ClientDonorSourceVideo.where(client_id: self.id, source_video_id: donor_video.id).first
					cdsv.recipient_source_video.destroy! unless cdsv.recipient_source_video.nil?
				end
			end
		end

  class << self
    def current_id=(id)
      Thread.current[:client_id] = id
    end

    def current_id
      Thread.current[:client_id]
    end

    def by_id(id)
      return all unless id.present?
      where("clients.id = ?", id.strip)
    end

    def by_name(name)
      return all unless name.present?
      where("lower(clients.name) like ?", "%#{name.downcase}%")
    end

    def by_email(email)
      return all unless email.present?
      where("lower(clients.email) like ?", "%#{email.downcase}%")
    end

    def by_industry_id(industry_id)
      return all unless industry_id.present?
      where("industries.id = ?", industry_id.strip)
    end

    def by_zipcode(zipcode)
      return all unless zipcode.present?
      where("lower(clients.zipcode) like ?", "%#{zipcode.downcase}%")
    end

    def by_locality(locality)
      return all unless locality.present?
      where("lower(clients.locality) like ?", "%#{locality.downcase}%")
    end

    def by_region(region)
      return all unless region.present?
      where("lower(clients.region) like ?", "%#{region.downcase}%")
    end

    def by_country(country)
      return all unless country.present?
      where("lower(clients.country) like ?", "%#{country.downcase}%")
    end

    def by_is_active(active)
      return all unless active.present?
      if active == true.to_s
        where("clients.is_active = true")
      else
        where("clients.is_active IS NOT TRUE")
      end
    end

    def by_visible(visible)
      return all unless visible.present?
      if visible == false.to_s
        where("clients.visible IS FALSE")
      else
        where("clients.visible IS NOT FALSE")
      end
    end

    def by_has_assets(has_assets)
      return all unless has_assets == "true"
      where("(client_landing_pages.client_id IS NOT NULL OR email_accounts.client_id IS NOT NULL)")
    end
  end
end
