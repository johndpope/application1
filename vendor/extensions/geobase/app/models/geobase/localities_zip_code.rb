class Geobase::LocalitiesZipCode < ActiveRecord::Base
  include Reversible
  belongs_to :zip_code
  belongs_to :locality
end