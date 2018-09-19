class Geobase::Locality < ActiveRecord::Base
  include Reversible
	belongs_to :primary_region, class_name: 'Geobase::Region', foreign_key: :primary_region_id
  # beg sid_changes
  belongs_to :secondary_region, class_name: 'Geobase::Region', foreign_key: :secondary_region_id
  belongs_to :ternary_region, class_name: 'Geobase::Region', foreign_key: :ternary_region_id
  belongs_to :quaternary_region, class_name: 'Geobase::Region', foreign_key: :quaternary_region_id
  # end sid_changes
	has_one :country, through: :primary_region
	has_and_belongs_to_many :zip_codes
	has_many :secondary_regions, -> { select("DISTINCT ON (geobase_regions.id) geobase_regions.*") }, through: :zip_codes
  has_many :landmarks
  has_many :neighbourhoods
  has_many :surroundings, :foreign_key => "locality_id", :class_name => "Geobase::Surrounding"
  has_many :neighbors, :through => :surroundings
  PROTECTED_WORDS = "town,towns,township,townships,village,villages,borough,boroughs,city,cities,county,counties,district,districts,municipality,municipalities,state,states,region,regions,country,countries"

	SEPARATOR = '<sep/>'
  TYPES = {'City' => 1, 'Town' => 2, 'Village' => 3, 'Borough' => 6, 'Census Designated Place' => 7, 'Unincorporated Community' => 8, 'Hamlet' => 9, 'Unknown' => nil}
  # beg sid_changes
  GEONAME_TYPES = {'PPL' => 1, 'PPLA' => 2, 'PPLA2' => 3, 'PPLA3' => 4, 'PPLA4' => 5, 'PPLC' => 6, 'PPLCH' => 7,
                   'PPLF' => 8, 'PPLG' => 9, 'PPLH' => 10, 'PPLL' => 11, 'PPLQ' => 12, 'PPLR' => 13, 'PPLS' => 14,
                   'PPLW' => 15, 'PPLX' => 16, 'STLMT' => 17}
  # end sid_changes

  extend Enumerize
	enumerize :locality_type, :in => TYPES
  # beg sid_changes
  enumerize :geonames_locality_type, :in => GEONAME_TYPES
  # end sid_changes

	scope :primary_region_code, ->(code) {
		joins(:primary_region).where("geobase_regions.code = '#{code}'").readonly(false)
	}

  def county
    secondary_regions.where("geobase_regions.level = 2").first
  end

	def self.locality_and_primary_region_name (locality_name, region_name)
		joins(:primary_region).where('LOWER(geobase_localities.name) = ? AND LOWER(geobase_regions.name) = ?', locality_name.downcase, region_name.downcase).readonly(false).first
	end

	def tier
		return nil unless population

		if population > 500000
			1
		elsif population.between?(100000, 500000)
			2
		elsif population.between?(50000, 99999)
			3
		elsif population.between?(25000, 49999)
			4
		elsif population.between?(10000, 24999)
			5
		elsif population.between?(5000, 9999)
			6
		elsif population.between?(2500, 4999)
			7
		else
			8
		end
	end

	def nickname_array
		nicknames.to_s.split(SEPARATOR)
	end

	def random_nickname
		nickname_array[rand(nickname_array.length)]
	end

	def random_zip_code
		self.zip_codes.shuffle.first.try(:code)
	end

  def description_count(description_name)
    Wording.where("name = ? AND resource_type = ? AND resource_id = ?", description_name, self.class.name, self.id).size
  end

	def self.by_id (id)
		return all unless id.present?
		where('geobase_localities.id = ?', id)
	end

	def self.by_primary_region_id (primary_region_id)
		return all unless primary_region_id.present?
		where('geobase_localities.primary_region_id = ?', primary_region_id)
	end

	def self.by_name (name)
		return all unless name.present?
		where('LOWER(geobase_localities.name) LIKE ?', "#{name.downcase}%")
	end

	def full_name
		"#{name} (#{locality_type})"
	end

  def name_with_parent_region(join_separator, region_name_part = "abbr")
    n = []
    n << name
    region = if primary_region.present?
      if primary_region.try(:parent).try(:parent).try(:parent).present?
        primary_region.parent.parent.parent
      elsif primary_region.try(:parent).try(:parent).present?
        primary_region.parent.parent
      elsif primary_region.parent.present?
        primary_region.parent
      else
        primary_region
      end
    end
    n << case region_name_part
    when "abbr"
        region.try(:code).to_s.gsub("US-", "").split(SEPARATOR).first.to_s
      when "full"
        region.try(:name).to_s
      else
        ""
    end
    n.reject{ |c| c.empty? }.join(join_separator).strip
  end

	def ids_by_radius(radius)
		if zip_code = zip_codes.to_a.first
        begin
    			ActiveRecord::Base.connection.
    				select_rows("SELECT get_locality_ids_by_radius(#{zip_code.latitude}, #{zip_code.longitude}, #{radius}, #{country.id})").flatten
        rescue
          []
        end
		else
			raise "Locality with ID #{self.id} doesn't have any Zip Code associated"
		end
	end

	def protected_words
    protected_words_from_settings = Setting.get_value_by_name("Geobase::Locality::PROTECTED_WORDS").split(",")
		protected_words_array = []
		protected_words_array << [self.name, self.name.downcase, self.name.upcase]
    abbr = self.code.to_s
    protected_words_array << abbr.split(SEPARATOR)
		protected_words_array << abbr.split(SEPARATOR).collect(&:downcase)
    protected_words_array << abbr.split(SEPARATOR).collect(&:upcase)
    protected_words_array << abbr.gsub("US-", "").split(SEPARATOR)
    protected_words_array << abbr.gsub("US-", "").split(SEPARATOR).collect(&:downcase)
    protected_words_array << abbr.gsub("US-", "").split(SEPARATOR).collect(&:upcase)
    protected_words_array << self.nicknames.to_s.split(SEPARATOR)
		protected_words_array << self.nicknames.to_s.split(SEPARATOR).collect(&:downcase)
    protected_words_array << self.nicknames.to_s.split(SEPARATOR).collect(&:upcase)
    primary_region = self.primary_region
    if primary_region.present?
      protected_words_array << [primary_region.try(:name), primary_region.try(:name).to_s.downcase, primary_region.try(:name).to_s.upcase]
      primary_region_abbr = primary_region.code.to_s
      protected_words_array << primary_region_abbr.split(SEPARATOR)
      protected_words_array << primary_region_abbr.split(SEPARATOR).collect(&:downcase)
      protected_words_array << primary_region_abbr.to_s.split(SEPARATOR).collect(&:upcase)
      protected_words_array << primary_region_abbr.gsub("US-", "").split(SEPARATOR)
      protected_words_array << primary_region_abbr.gsub("US-", "").split(SEPARATOR).collect(&:downcase)
      protected_words_array << primary_region_abbr.gsub("US-", "").split(SEPARATOR).collect(&:upcase)
      protected_words_array << primary_region.try(:nicknames).to_s.split(SEPARATOR)
      protected_words_array << primary_region.try(:nicknames).to_s.split(SEPARATOR).collect(&:downcase)
      protected_words_array << primary_region.try(:nicknames).to_s.split(SEPARATOR).collect(&:upcase)
      parent_region = primary_region.parent
      if parent_region.present?
        protected_words_array << [parent_region.name, parent_region.name.downcase, parent_region.name.upcase]
        parent_region_abbr = parent_region.code.to_s
        protected_words_array << parent_region_abbr.split(SEPARATOR)
        protected_words_array << parent_region_abbr.split(SEPARATOR).collect(&:downcase)
        protected_words_array << parent_region_abbr.split(SEPARATOR).collect(&:upcase)
        protected_words_array << parent_region_abbr.gsub("US-", "").split(SEPARATOR)
        protected_words_array << parent_region_abbr.gsub("US-", "").split(SEPARATOR).collect(&:downcase)
        protected_words_array << parent_region_abbr.gsub("US-", "").split(SEPARATOR).collect(&:upcase)
        protected_words_array << parent_region.nicknames.to_s.split(SEPARATOR)
        protected_words_array << parent_region.nicknames.to_s.split(SEPARATOR).collect(&:downcase)
        protected_words_array << parent_region.nicknames.to_s.split(SEPARATOR).collect(&:upcase)
      end
    end
    protected_words_array << protected_words_from_settings
    protected_words_array << protected_words_from_settings.collect(&:capitalize)
    protected_words_array << protected_words_from_settings.collect(&:upcase)
		protected_words_array.flatten.compact.collect(&:strip).reject(&:blank?).uniq.join(",")
	end

	def formatted_name(options = {})
		options = {primary_region: false, primary_region_code: true, country: false, country_code: false}.merge options
		parts = [name]
		if options[:primary_region] == true && !primary_region.blank?
			parts << (options[:primary_region_code] == true ? primary_region.try(:code).try(:split, '<sep/>').try(:first).try(:split, '-').try(:last) : primary_region.try(:name))
		end
		if options[:country] == true && !country.blank?
			parts << (options[:country_code] == true ? country.try(:code).try(:split, '-').try(:last) : country.try(:name))
		end

		parts.join(', ')
	end
end
