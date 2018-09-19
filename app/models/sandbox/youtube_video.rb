class Sandbox::YoutubeVideo < ActiveRecord::Base
  include CSVAccessor

  belongs_to :sandbox_client, class_name: "::Sandbox::Client", foreign_key: "sandbox_client_id"
  belongs_to :location, polymorphic: true

  serialize :title_product_components, Array
  serialize :title_subject_components, Array
  serialize :title_entity_components, Array
  serialize :descriptions, Array

  has_csv_accessors_for :title_product_components
  has_csv_accessors_for :title_subject_components
  has_csv_accessors_for :title_entity_components
  has_sep_accessors_for :descriptions

  validates :sandbox_client_id, :title_product_components_csv, :title_subject_components_csv, :title_entity_components_csv, :descriptions_sep, presence: true
  validate :validate_location_type
  def validate_location_type
    if !location_type.present? || location_type == 'Geobase::Country'
      errors.add(:location_type, "Country, State or County or City can't be blank")
    end
  end
end
