module ImageFilters
	module FwFilters
		class Bevelborder::SanDiego < Bevelborder
			class << self
				def default_options
					{s:25, m:'outer', c:75, a:25}
				end
			end
		end
	end
end
