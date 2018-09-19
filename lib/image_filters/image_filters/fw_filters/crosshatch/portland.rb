module ImageFilters
	module FwFilters
		class Crosshatch::Portland < Crosshatch
			class << self
				def default_options
					{l:7, s:0, g:0, a:1}
				end
			end
		end
	end
end
