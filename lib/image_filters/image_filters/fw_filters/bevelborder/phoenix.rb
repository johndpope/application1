module ImageFilters
	module FwFilters
		class Bevelborder::Phoenix < Bevelborder
			class << self
				def default_options
					{s:25, m:'split', c:50, p:75}
				end
			end
		end
	end
end
