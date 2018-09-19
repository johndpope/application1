module ImageFilters
	module FwFilters
		class Sketch
			extend Base
			class << self
				def default_options
					{k:'desat', e:4, c:125, s:100, g:''}
				end

				def filter_name
					'sketch'
				end
			end
		end
	end
end
