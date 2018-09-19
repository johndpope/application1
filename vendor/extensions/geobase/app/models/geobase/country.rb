class Geobase::Country < ActiveRecord::Base
  include Reversible
  has_many :regions
  has_many :localities, through: :regions
  has_many :landmarks

  def formatted_name
    name
  end
end
