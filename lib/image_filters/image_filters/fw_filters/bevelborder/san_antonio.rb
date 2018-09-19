module ImageFilters
	module FwFilters
		class Bevelborder::SanAntonio < Bevelborder
			class << self
				def default_options
					{s:25, m:'inner', c:75, a:25}
				end
			end
		end
	end
end
