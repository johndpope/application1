class BlendingPattern < ActiveRecord::Base
	include Reversible
	SEPARATOR = ","

	belongs_to :client
	belongs_to :product
	belongs_to :source_video

	attr_accessor :items
	validate :pattern_values

	def values
		value.to_s.split(",")
	end

	def pattern_values
		if values.blank?
			errors.add(:value, I18n.t("blending_pattern.errors.empty"))
		else
			errors.add(:value, I18n.t("blending_pattern.errors.subject_is_not_presented")) if !values.include?('subject')
		end
	end

 	class << self
		def generic
			where(client_id: nil, product_id: nil, source_video_id: nil)
		end
	end
end
