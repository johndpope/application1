module ImageFilters
	module FwFilters
		class Coloration
			extend Base
			class << self
				def default_options
					{h:0, s:50, l:0, u:'degrees', r: 29.9, g: 58.7, b:11.4, B:10, C:-10}
				end

				def filter_name
					'coloration'
				end
			end
		end
	end
end
