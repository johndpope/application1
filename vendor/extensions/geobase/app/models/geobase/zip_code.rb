class Geobase::ZipCode < ActiveRecord::Base
  include Reversible
  belongs_to :primary_region, class_name: 'Geobase::Region', foreign_key: :primary_region_id
  belongs_to :secondary_region, class_name: 'Geobase::Region', foreign_key: :secondary_region_id
  # beg sid_changes
  belongs_to :ternary_region, class_name: 'Geobase::Region', foreign_key: :ternary_region_id
  # end sid_changes

  has_and_belongs_to_many :localities

  scope :primary_region_code, ->(code) do
    joins(:primary_region).where("geobase_regions.code = '#{code}'").readonly(false)
  end
  scope :country_code, ->(code) do
    joins(:primary_region).joins(:country).where("geobase_countries.code = '#{code}'").readonly(false)
  end

  EARTH_MEAN_RADIUS = 3958.761
  MI_KM_CONVERSION = 1.60934

  def within(options = {})
    radius = options[:radius] || 0
    unit = options[:unit] || :kilometer
    radius *= MI_KM_CONVERSION if unit == :mile
    distance = %Q[
        (
            #{EARTH_MEAN_RADIUS} *
            acos(
                sin(radians(#{self.latitude})) * sin(radians(latitude)) +
                cos(radians(#{self.latitude})) * cos(radians(latitude)) *
                cos(radians(#{self.longitude}) - radians(longitude))
            )
        )
    ]
    self.class.find_by_sql(%Q[
      SELECT *, #{distance} as d
      FROM geobase_zip_codes WHERE #{radius} >= #{distance} AND code != '#{self.code}'
      ORDER BY d
    ])
  end
end
