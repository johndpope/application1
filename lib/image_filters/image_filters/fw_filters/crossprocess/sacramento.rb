module ImageFilters
	module FwFilters
		class Crossprocess::Sacramento < Crossprocess
			class << self
				def default_options
					{r:100, g:-25}
				end
			end
		end
	end
end
