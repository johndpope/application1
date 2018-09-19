module ImageFilters
	module FwFilters
		# Applies accented edges to an image.
		class Accentedges
			extend Base
			class << self
				# Filter's default options
				# @return [Hash]
				#   * :w [Integer] Width of edges; >0
				#   * :s [Integer] Strenght of edges; >=0
				#   * :p [String] Polarity of edges; choices are: white or black
				#   * :b [Float] Blurring (smoothing) of edges; float>=0
				#   * :c [String] Compose method for blending edges with image; choices are: over or overlay; default=over
				#
				def default_options
					{w: 1, s: 20, p: 'black', b: 0.5, c: 'over'}
				end

				def filter_name
					'accentedges'
				end
			end
		end
	end
end
