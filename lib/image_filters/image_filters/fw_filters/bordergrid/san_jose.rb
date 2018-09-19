module ImageFilters
	module FwFilters
		class Bordergrid::SanJose < Bordergrid
			class << self
				def default_options
					{s:20, t:4, o:2, d:2, a:45, c:'white', b:0}
				end
			end
		end
	end
end
