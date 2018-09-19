class TechnicalTag < ActiveRecord::Base
	extend FriendlyId
	friendly_id :name, use: :slugged

	def to_param
		id
	end

	def should_generate_new_friendly_id?
	    true
  	end
end
