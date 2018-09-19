module ImageFilters
	module FwFilters
		class Crosshatch::Milwaukee < Crosshatch
			class << self
				def default_options
					{l:7, s:10, g:1, a:10}
				end
			end
		end
	end
end
