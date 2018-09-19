module ImageFilters
	module FwFilters
		class Cartoon::ElPaso < Cartoon
			class << self
				def default_options
					{p:70, n:6, m:2, e:4, b:100, s:150}
				end
			end
		end
	end
end
