module ImageFilters
	module FwFilters
		class Crosshatch::LasVegas < Crosshatch
			class << self
				def default_options
					{l:7, s:10, g:5, a:10}
				end
			end
		end
	end
end
