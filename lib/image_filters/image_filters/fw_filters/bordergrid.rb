module ImageFilters
	module FwFilters
		class Bordergrid
			extend Base
			class << self
				def default_options
					{s:5, t:10, o:3, d:1, a:45, c:'', b:0}
				end

				def filter_name
					'bordergrid'
				end
			end
		end
	end
end
