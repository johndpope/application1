module ImageFilters
	module FwFilters
		class Bevelborder::Chicago < Bevelborder
			class << self
				def default_options
					{s:25, m:'split'}
				end
			end
		end
	end
end
