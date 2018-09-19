module ImageFilters
	module FwFilters
		class Bordereffects::Austin < Bordereffects
			class << self
				def default_options
					{s:10, d:5, c:5, g:1, b:'white', p:2, r:2}
				end
			end
		end
	end
end
