class VideoMarketingCampaignForm < ActiveRecord::Base
  include CSVAccessor
  include RegexPatterns
  include Referable
  include Reversible
  extend Enumerize
  EMAIL_RECEIVERS = "tmriordan@gmail.com,zavorotnii@gmail.com,serghei.topor@gmail.com,black3mamba@gmail.com,simeniuk.natasha@gmail.com,royce@machonemediagroup.com"
  LOCALITIES_SEARCH_RADIUS = 50

  #revert tag_list
  validates :primary_brand, :company_name, :address1, :zipcode, :locality, :region, :primary_phone, :company_email,:company_nickname, presence: true
  #validate :descriptions_presence

  has_many :wordings, as: :resource
  has_many :aae_project_dynamic_texts, class_name: "Templates::AaeProjectDynamicText"
  belongs_to :industry
  belongs_to :client
  serialize :"wordings", Array
  has_csv_accessors_for "wordings"
  has_references_for :wordings
  accepts_nested_attributes_for :wordings, allow_destroy: true, reject_if: ->(attributes) { attributes[:source].blank? && attributes[:name].blank? }

  serialize :distributor_names, Array
  has_csv_accessors_for "distributor_names"

  acts_as_taggable

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

  before_create :create_client
  after_create :add_summary_points
  after_initialize :init
  before_save :clean_brands
  validate :selected_cities_for_package, :selected_brands_for_production
  validates :has_youtube_channel, :no_website, inclusion: {in: [true, false], message: "Please answer a question"}
  validates :website, presence: {message: "Please introduce a website"}, if: Proc.new { |a| a.no_website == false }
  validates :agree_to_terms_of_use, inclusion: {in: [true], message: "Please agree to the Terms of Use and Privacy Policy in order to use our service."}
  before_validation :set_agree_to_terms_of_use_datetime

  PACKAGE_TYPES = {basic: 1, better: 2, best: 3, custom: 4, youtube: 5}
  PACKAGE_INFO = {basic: {id: 1, name: "Basic Package", price: 1200, price_formatted: "$1,200", locations: 1, cart_description: "(1 Locations x 5 Subject Videos = 5 Videos)"}, better: {id: 2, name: "Better Package", price: 4000, price_formatted: "$4,000", locations: 3, cart_description: "(3 Locations x 3 Subject Videos = 9 Videos)"}, best: {id: 3, name: "Best Package", price: 6000, price_formatted: "$6,000", locations: 5, cart_description: "(5 Locations x 5 Subject Videos = 25 Videos)"}, custom: {id: 4, name: "Custom Package", price: 0, price_formatted: "", locations: 0, cart_description: ""}, youtube: {id: 5, name: "Basic Package", price: 1200, price_formatted: "$1,200", locations: 1, cart_description: "(1 Location x 5 Subject Videos = 5 Videos)"}}
	enumerize :package_type, in: PACKAGE_TYPES

  # def selected_brands
  #   brands_selected = self.brands.to_a
  #   brands_selected.delete("0")
  #   if !brands_selected.present?
  #     errors.add(:brands, "Select at least one brand")
  #   end
  # end

  def selected_cities_for_package
    if self.id.present? && self.package_type.present? && self.cities.to_a.size < VideoMarketingCampaignForm::PACKAGE_INFO[self.package_type.to_sym][:locations]
      errors.add(:cities, "Not enough selected localities #{self.cities.to_a.size}/#{VideoMarketingCampaignForm::PACKAGE_INFO[self.package_type.to_sym][:locations]}")
    end
  end

  def selected_brands_for_production
    brands_selected = self.brands_for_production.to_a
    brands_selected.delete("0")
    if self.id.present? && !brands_selected.present?
      errors.add(:brands_for_production, "Select at least one brand")
    end
  end

  def clean_brands
    self.brands = self.brands.to_a - [self.primary_brand.to_s]
  end

  def init
    self.package_type ||= VideoMarketingCampaignForm.package_type.find_value(:best).value
  end

  def descriptions_presence
    if self.wordings.to_a.select {|w| w.name == 'short_description'}.size < Client::MINIMUM_SHORT_DESCRIPTIONS
      errors.add(:wordings, "Short descriptions are less than #{Client::MINIMUM_SHORT_DESCRIPTIONS}")
    end
    if self.wordings.to_a.select {|w| w.name == 'long_description'}.size < Client::MINIMUM_LONG_DESCRIPTIONS
      errors.add(:wordings, "Long descriptions are less than #{Client::MINIMUM_LONG_DESCRIPTIONS}")
    end
  end

  def company_phones
    (read_attribute(:company_phones) || []).map do |p|
      #p.gsub(/[^\d]/, '')
      p =~ /^\d{12}$/ ? "#{p[0..1]}(#{p[2..4]}) #{p[5..7]}-#{p[8..12]}" : p
    end
  end

  def company_phones_csv
    company_phones.try(:join, ', ')
  end

  def company_phones_csv=(values)
    self.company_phones = values.strip.split(/\s*,\s*/)
  end

  def contact_phones
    (read_attribute(:contact_phones) || []).map do |p|
      #p.gsub(/[^\d]/, '')
      p =~ /^\d{12}$/ ? "#{p[0..1]}(#{p[2..4]}) #{p[5..7]}-#{p[8..12]}" : p
    end
  end

  def contact_phones_csv
    contact_phones.try(:join, ', ')
  end

  def contact_phones_csv=(values)
    self.contact_phones = values.strip.split(/\s*,\s*/)
  end

  def representative_phones
    (read_attribute(:representative_phones) || []).map do |p|
      #p.gsub(/[^\d]/, '')
      p =~ /^\d{12}$/ ? "#{p[0..1]}(#{p[2..4]}) #{p[5..7]}-#{p[8..12]}" : p
    end
  end

  def representative_phones_csv
    representative_phones.try(:join, ', ')
  end

  def representative_phones_csv=(values)
    self.representative_phones = values.strip.split(/\s*,\s*/)
  end

  def detect_other_localities
    if self.zipcode.present?
      zip = Geobase::ZipCode.where(code: self.zipcode.first(5)).first
      if zip.present?
        primary_locality_id = zip.localities.sort{|a, b| b.population.to_i <=> a.population.to_i}.first.try(:id)
        if primary_locality_id.present?
          self.cities = [primary_locality_id.to_s] + Geobase::Locality.where(id: Geobase::Locality.find(primary_locality_id).ids_by_radius(Setting.get_value_by_name("VideoMarketingCampaignForm::LOCALITIES_SEARCH_RADIUS").to_i)).where.not(id: primary_locality_id).order("population DESC NULLS LAST").pluck(:id).first(4)
        end
      end
    end
  end

  private

    def create_client
      client = Client.new(name: self.company_name.to_s.strip, is_active: false, industry_id: self.industry_id)
      client.save(validate: false)
      self.client_id = client.id
      self.brands_for_production = [self.primary_brand.to_s]
      self.contact_first_name = self.representative_first_name
      self.contact_last_name = self.representative_last_name
      self.contact_email = self.representative_email
      self.contact_phones_csv = self.representative_phones_csv
    end

    def add_summary_points
      self.try(:industry).try(:summary_points).to_a.each do |v|
        self.wordings << Wording.new(name: "summary_point", source: v)
      end
    end

    def before_save
      %w(logo badge_logo).each do |l|
        self.send("#{l}=", nil) if self.send("remove_#{l}") == 'true'
      end
    end

    def set_agree_to_terms_of_use_datetime
      self.agree_to_terms_of_use_at = Time.now if self.agree_to_terms_of_use_changed? && self.agree_to_terms_of_use
    end
end
