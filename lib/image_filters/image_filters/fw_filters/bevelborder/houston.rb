module ImageFilters
	module FwFilters
		class Bevelborder::Houston < Bevelborder
			class << self
				def default_options
					{s:25, m:'split', p:75}
				end
			end
		end
	end
end
