module ImageFilters
	module FwFilters
		class Thermography::Tulsa < Thermography
			class << self
				def default_options
					{l:50, h:100}
				end
			end
		end
	end
end
