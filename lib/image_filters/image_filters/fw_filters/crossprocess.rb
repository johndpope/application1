module ImageFilters
	module FwFilters
		class Crossprocess
			extend Base
			class << self
				def default_options
					{r:0, g:0, b:0, B:0, C:0}
				end

				def filter_name
					'crossprocess'
				end
			end
		end
	end
end
