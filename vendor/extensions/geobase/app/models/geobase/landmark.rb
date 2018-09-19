class Geobase::Landmark < ActiveRecord::Base
  include Reversible
  belongs_to :region
  belongs_to :locality
  belongs_to :country
  belongs_to :neighbourhood

	def self.by_id(id)
    return all unless id.present?
    where("geobase_landmarks.id = ?", id)
  end

  def self.by_name(name)
    return all unless name.present?
    where('LOWER(geobase_landmarks.name) LIKE ?', "#{name.downcase}%")
  end
end
