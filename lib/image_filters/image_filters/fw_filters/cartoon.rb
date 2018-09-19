module ImageFilters
	module FwFilters
		class Cartoon
			extend Base
			class << self
				def default_options
					{p:70, n:6, m:1, e:4, b:100, s:150}
				end

				def filter_name
					'cartoon'
				end
			end
		end
	end
end
