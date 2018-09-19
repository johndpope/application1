module ImageFilters
	module FwFilters
		class Thermography::Cleveland < Thermography
			class << self
				def default_options
					{l:0, h:50}
				end
			end
		end
	end
end
