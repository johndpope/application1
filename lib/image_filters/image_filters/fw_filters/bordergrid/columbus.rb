module ImageFilters
	module FwFilters
		class Bordergrid::Columbus < Bordergrid
			class << self
				def default_options
					{s:20, t:3, o:3, d:2, a:0, c:'white', b:0}
				end
			end
		end
	end
end
