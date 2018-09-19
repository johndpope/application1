module ImageFilters
	module FwFilters
		class Lichtenstein
			extend Base
			class << self
				def default_options
					{p:7, b:3, s:2, d:'o8x8', B:1, e:2, g:5, E:1, S:175}
				end

				def filter_name
					'lichtenstein'
				end
			end
		end
	end
end
