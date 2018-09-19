class Geobase::Surrounding < ActiveRecord::Base
  belongs_to :locality, :foreign_key => "locality_id", :class_name => "Geobase::Locality"
  belongs_to :neighbor, :foreign_key => "neighbor_id", :class_name => "Geobase::Locality"
end
