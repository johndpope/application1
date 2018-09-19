module ImageFilters
	module FwFilters
		class Sketch::Arlington < Sketch
			class << self
				def default_options
					{k:'desat', c:125, s:100, e:8}
				end
			end
		end
	end
end
