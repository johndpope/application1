module ImageFilters
	module FwFilters
		class Sketchetch::Tampa < Sketchetch
			class << self
				def default_options
					{m:'composite', e:5, t:'hardlight'}
				end
			end
		end
	end
end
