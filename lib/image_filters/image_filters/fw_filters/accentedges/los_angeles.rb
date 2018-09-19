module ImageFilters
	module FwFilters
		class Accentedges::LosAngeles < Accentedges
			class << self
				def default_options
					{w: 1, s: 100, p: 'black', b: 0.5, c: 'over'}
				end
			end
		end
	end
end
