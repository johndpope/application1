class Geobase::Neighbourhood < ActiveRecord::Base
  include Reversible
	belongs_to :locality, class_name: 'Geobase::Locality', foreign_key: :locality_id
  has_many :landmarks

  def description_count(description_name)
    Wording.where("name = ? AND resource_type = ? AND resource_id = ?", description_name, self.class.name, self.id).size
  end
end
