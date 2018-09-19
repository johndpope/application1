module ImageFilters
	module FwFilters
		class Cartoon::Detroit < Cartoon
			class << self
				def default_options
					{p:80, n:6, m:1, e:4, b:100, s:150}
				end
			end
		end
	end
end
