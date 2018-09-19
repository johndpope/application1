module ImageFilters
	module FwFilters
		class Sketchetch::NewOrleans < Sketchetch
			class << self
				def default_options
					{m:'colorized', e:5, C:50}
				end
			end
		end
	end
end
