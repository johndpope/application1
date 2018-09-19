module ImageFilters
	module FwFilters
		class Bevelborder::Philadelphia < Bevelborder
			class << self
				def default_options
					{s:25, m:'split', c:50, p:25}
				end
			end
		end
	end
end
