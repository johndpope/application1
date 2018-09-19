class Domain < ActiveRecord::Base
  include Reversible
  validates :name, presence: true
  validates :name, uniqueness: true

  class << self
		def by_id(id)
			return all unless id.present?
			where('domains.id = ?', id.strip)
		end

		def by_name(name)
			return all unless name.present?
			where('lower(domains.name) like ?', "%#{name.downcase}%")
		end

    def by_parked(parked)
  		return all unless parked.present?
  		if parked == true.to_s
  			where('domains.parked = TRUE')
  		else
  			where('domains.parked IS NOT TRUE')
  		end
  	end
  end
end
