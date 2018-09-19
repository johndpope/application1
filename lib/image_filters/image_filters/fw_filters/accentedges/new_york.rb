module ImageFilters
	module FwFilters
		class Accentedges::NewYork < Accentedges
			class << self
				def default_options
					{w: 6, s: 20, p: 'black', b: 0.5, c: 'over'}
				end
			end
		end
	end
end
