module ImageFilters
	module FwFilters
		class Sketch::Wichita < Sketch
			class << self
				def default_options
					{k:'gray', c:175}
				end
			end
		end
	end
end
