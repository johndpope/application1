module ImageFilters
	module FwFilters
		class Sketchetch
			extend Base
			class << self
				def default_options
					{m:'normal', e:4, B:0, H:0, S:0, c:'sienna1', C:50, t:'hardlight'}
				end

				def filter_name
					'sketchetch'
				end

				def script_executor
					'bash'
				end
			end
		end
	end
end
