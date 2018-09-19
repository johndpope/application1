module ImageFilters
	module FwFilters
		class Bordereffects
			extend Base
			class << self
				def default_options
					{s:5, d:5, c:5, g:1, b:'white', p:2, r:2}
				end

				def filter_name
					'bordereffects'
				end
			end
		end
	end
end
