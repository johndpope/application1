module ImageFilters
	module FwFilters
		class Bordergrid::SanFrancisco < Bordergrid
			class << self
				def default_options
					{s:20, t:2, o:4, d:1, a:-45, c:'white', b:0}
				end
			end
		end
	end
end
