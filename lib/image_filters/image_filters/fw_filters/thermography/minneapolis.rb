module ImageFilters
	module FwFilters
		class Thermography::Minneapolis < Thermography
			class << self
				def default_options
					{l:0, h:100}
				end
			end
		end
	end
end
