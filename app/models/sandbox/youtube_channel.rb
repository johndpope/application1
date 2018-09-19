class Sandbox::YoutubeChannel < ActiveRecord::Base
  include CSVAccessor

  belongs_to :sandbox_client, class_name: "::Sandbox::Client", foreign_key: "sandbox_client_id"
  belongs_to :location, polymorphic: true

  serialize :title_subject_components, Array
  serialize :title_entity_components, Array
  serialize :title_descriptor_components, Array

  serialize :client_short_description, Array
  serialize :industry_short_description, Array
  serialize :location_short_description, Array
  serialize :other_short_description, Array

  has_csv_accessors_for :title_subject_components
  has_csv_accessors_for :title_entity_components
  has_csv_accessors_for :title_descriptor_components

  CHANNEL_DESCRIPTION_TYPES = {"client_short_description" => 1, "industry_short_description" => 2, "location_short_description" => 3, "other_short_description" => 4}
  validates :sandbox_client_id, :title_subject_components_csv, :title_entity_components_csv, :title_descriptor_components_csv, presence: true
  validate :validate_location_type
  def validate_location_type
    if !location_type.present? || location_type == 'Geobase::Country'
      errors.add(:location_type, "Country, State or County or City can't be blank")
    end
  end

  descriptions = %w(client industry location other)
  descriptions.each do |item|
    eval(
    "def #{item}_short_description_sep
      #{item}_short_description.try(:join, ', ')
    end"
    )

    eval(
    "def #{item}_short_description_sep=(values)
      puts values
      values.delete('')
      unless values.blank?
        self.#{item}_short_description = values
      else
        self.#{item}_short_description = nil
      end
    end"
    )
  end
end
