class Geobase::RegionAttributes
	attr_accessor :capital, :song, :colors, :spoken_languages, :sport_teams, :fish, :largest_city, :largest_metropolitan_area, :slogan, :dance, :amphibian, :animal, :insect, :tree, :fruit, :metropolitan_statistical_area, :county_seat, :motto, :flower, :bird

	def initialize
		%w(capital song colors spoken_languages sport_teams fish largest_city largest_metropolitan_area slogan dance amphibian animal insect tree fruit metropolitan_statistical_area county_seat motto flower bird).each { |a| self.instance_variable_set("@#{a}", []) }
	end

	def self.build(params = {})
		res = Geobase::RegionAttributes.new
		params.each { |k, v| res.instance_variable_set("@#{k}", v.to_s.split(",").collect(&:strip).join(",")) }
		res
	end
end

class Geobase::Region < ActiveRecord::Base
  include Reversible
	belongs_to :country
	belongs_to :parent, class_name: 'Geobase::Region', foreign_key: :parent_id
	has_many :localities, foreign_key: :primary_region_id
  has_many :landmarks
	serialize :region_attributes, Geobase::RegionAttributes
	scope :parent_code, ->(code) {
		joins(:parent).where("parents_geobase_regions.code = '#{code}'").readonly(false)
	}

	SEPARATOR = '<sep/>'

	def self.by_name (name)
		return nil if name.blank?
		where('LOWER(name) = ?', name.downcase).first
	end

	def self.by_id (id)
		return all unless id.present?
		where('geobase_regions.id = ?', id)
	end

	def self.by_name_field (name)
		return all unless name.present?
		where('LOWER(geobase_regions.name) LIKE ?', "%#{name.downcase}%")
	end

	def self.locality_and_region_name (locality_name, region_name)
		joins('INNER JOIN localities ON (geobase_localities.primary_region_id = regions.id)').where('LOWER(geobase_localities.name) = ? AND LOWER(geobase_regions.name) = ?', locality_name.downcase, region_name.downcase).readonly(false).first
	end

	def self.county(county_name, state_name)
		joins(:parent).where("geobase_regions.name = ? AND parents_geobase_regions.name = ?", county_name, state_name).first
	end

	def nickname_array
		nicknames.to_s.split(SEPARATOR)
	end

	def random_nickname
		nickname_array[rand(nicknames_array.length)]
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
    parent_region = self.parent
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
    protected_words_array << protected_words_from_settings
    protected_words_array << protected_words_from_settings.collect(&:capitalize)
    protected_words_array << protected_words_from_settings.collect(&:upcase)
		protected_words_array.flatten.compact.collect(&:strip).reject(&:blank?).uniq.join(",")
	end

	def formatted_name(options = {})
		options = {primary_region: false, primary_region_code: true, country: false, country_code: false}.merge options
		name_parts = [name]
		name_parts << 'County' if !country.blank? && country.code.downcase == 'us' && level == 2 && !name.downcase.include?('county')
		parts = [name_parts.join(' ')]

		if options[:primary_region] == true && !parent.blank?
			parts << (options[:primary_region_code] == true ? parent.try(:code).try(:split, '<sep/>').try(:first).try(:split, '-').try(:last) : parent.try(:name))
		end
		if options[:country] == true && !country.blank?
			parts << (options[:country_code] == true ? country.try(:code).try(:split, '-').try(:last) : country.try(:name))
		end

		parts.join(', ')
	end
end
