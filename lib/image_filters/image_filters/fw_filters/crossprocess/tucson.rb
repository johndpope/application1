module ImageFilters
	module FwFilters
		class Crossprocess::Tucson < Crossprocess
			class << self
				def default_options
					{r:-50, b:50, B:5, C:5}
				end
			end
		end
	end
end
