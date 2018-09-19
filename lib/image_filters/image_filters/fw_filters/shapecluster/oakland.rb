module ImageFilters
	module FwFilters
		class Shapecluster::Oakland < Shapecluster
			class << self
				def default_options
					{t:15, b:0}
				end
			end
		end
	end
end
