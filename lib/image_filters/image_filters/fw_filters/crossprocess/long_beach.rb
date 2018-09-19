module ImageFilters
	module FwFilters
		class Crossprocess::LongBeach < Crossprocess
			class << self
				def default_options
					{r:-50, B:20, C:-20}
				end
			end
		end
	end
end
