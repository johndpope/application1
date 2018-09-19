module ImageFilters
	module FwFilters
		class Shapecluster
			extend Base
			class << self
				def default_options
					{t:10, d:60, r:2, e:5, b:20, c:'white'}
				end

				def filter_name
					'shapecluster'
				end
			end
		end
	end
end
