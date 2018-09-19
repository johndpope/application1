module ImageFilters
	module FwFilters
		class Crossprocess::Mesa < Crossprocess
			class << self
				def default_options
					{r:-50}
				end
			end
		end
	end
end
