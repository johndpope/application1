module ImageFilters
	module FwFilters
		class Bordereffects::Indianapolis < Bordereffects
			class << self
				def default_options
					{s:10, d:2, c:2, g:1, b:'white', p:2, r:2}
				end
			end
		end
	end
end
