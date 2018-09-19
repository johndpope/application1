class Industry < ActiveRecord::Base
  include CSVAccessor
  include Referable
	include Reversible
  belongs_to :parent, class_name: 'Industry', foreign_key: :parent_id
  has_many :children, -> { order(code: :asc) }, class_name: "Industry", foreign_key: :parent_id
	has_many :wordings, as: :resource
	validates :code, uniqueness: true
  validates :nickname, presence: true
  validates :nickname, length: { maximum: 10 }
  validates :business_channel_title_patterns, :business_video_title_patterns, presence: true

  serialize :"wordings", Array
	has_csv_accessors_for "wordings"

	has_references_for :wordings
	accepts_nested_attributes_for :wordings, allow_destroy: true, reject_if: ->(attributes) { attributes[:source].blank? && attributes[:name].blank? }

  %w(business).each do | i |
    %w(channel video).each do | j |
      %w(entity subject descriptor).each do | k |
        serialize :"#{i}_#{j}_#{k}", Array
        has_csv_accessors_for :"#{i}_#{j}_#{k}"
      end
    end
  end

  serialize :industry_title_components, Array
  serialize :alternate_names, Array
  serialize :summary_points, Array
  has_csv_accessors_for :alternate_names
  has_csv_accessors_for :industry_title_components
  has_csv_accessors_for :summary_points

	acts_as_taggable

  def self.by_id(id)
    return all unless id.present?
    where("industries.id = ?", id.strip)
  end

  def self.by_code(code)
    return all unless code.present?
    where("industries.code = ?", code.strip)
  end

	def self.by_code_or_name (value)
		if value.present?
			Industry.where('code LIKE ? OR LOWER(name) LIKE ?', "#{value.strip.downcase}%", "%#{value.strip.downcase}%").order('LENGTH(code), code')
		else
			self.by_code_length(2)
		end
	end

	def self.by_code_length (value)
		Industry.where('LENGTH(code) = ?', value).order('LENGTH(code), code')
	end

	def display_code
		case code
		when '31'
		  '31-33'
		when '44'
		  '44-45'
		when '48'
		  '48-49'
		else
			code
		end
	end

  def top_level
    unless self.code.size == 2
      top_level_code = self.code.first(2)
      final_code = case top_level_code
  		when '32', '33'
  		  '31'
  		when '45'
  		  '44'
  		when '49'
  		  '48'
  		else
  			top_level_code
  		end
      Industry.find_by_code(final_code)
    end
  end

  def json
    json_object = {}
		json_object =  JSON.parse(self.to_json)
    json_object['short_descriptions_count'] = description_wordings_size('short_description')
    json_object['long_descriptions_count'] = description_wordings_size('long_description')
    json_object['tag_list_count'] = self.tag_list.size
    json_object
  end

	def display_name
		"#{self.display_code} · #{self.name}"
	end

  def short_name
    nickname.present? ? nickname : name
  end

	def source_url
		'https://www.census.gov/cgi-bin/sssd/naics/naicsrch?code=' + self.code.to_s + '&search=2012%20NAICS%20Search'
	end

  def images_count
    Artifacts::Image.where("industry_id = ?", self.id).size
  end

  def description_wordings_size(name)
    Wording.where("resource_id = ? AND resource_type = 'Industry' AND name = ?", self.id, name).size
  end

	def description_wording(name)
		self.id.present? ? Wording.where("resource_id = ? AND resource_type = 'Industry' AND name = ?", self.id, name).order(created_at: :desc).shuffle.first : nil
	end
end
