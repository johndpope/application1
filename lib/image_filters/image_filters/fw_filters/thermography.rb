module ImageFilters
	module FwFilters
		class Thermography
			extend Base
			class << self
				def default_options
					{l:0, h:100}
				end

				def filter_name
					'thermography'
				end
			end
		end
	end
end
