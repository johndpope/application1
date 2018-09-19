class BlendingPatternService
	class << self
		def random_blending_pattern(source_video)
			criteria = nil
			["source_video_id = #{source_video.id}",
				"source_video_id IS NULL AND product_id = #{source_video.product_id}",
				"source_video_id IS NULL AND product_id IS NULL AND client_id = #{source_video.client.id}"].each do |q|
				if BlendingPattern.where(q).exists?
					criteria = q
				end
			end
			scope = BlendingPattern.order('RANDOM()')
			return criteria.blank? ? scope.generic.first : scope.where(criteria).first
		end
	end
end
