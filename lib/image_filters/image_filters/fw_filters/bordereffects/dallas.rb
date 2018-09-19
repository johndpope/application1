module ImageFilters
	module FwFilters
		class Bordereffects::Dallas < Bordereffects
			class << self
				def default_options
					{s:10, d:5, c:1, g:1, b:'white', p:2, r:2}
				end
			end
		end
	end
end
