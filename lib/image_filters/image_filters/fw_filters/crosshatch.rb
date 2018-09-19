module ImageFilters
	module FwFilters
		class Crosshatch
			extend Base
			class << self
				def default_options
					{l:7, s:10, g:1, a:1, p:0, b:0, e:'normal', m:100, B:0, C:0, S:0}
				end

				def filter_name
					'crosshatch'
				end

				def script_executor
					'bash'
				end
			end
		end
	end
end
