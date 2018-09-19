module ImageFilters
	module FwFilters
		class Crosshatch::Oklahoma < Crosshatch
			class << self
				def default_options
					{l:7, s:5, g:0, a:1}
				end
			end
		end
	end
end
