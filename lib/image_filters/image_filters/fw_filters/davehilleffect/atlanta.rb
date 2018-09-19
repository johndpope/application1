module ImageFilters
	module FwFilters
		class Davehilleffect::Atlanta < Davehilleffect
			class << self
				def default_options
					{b:1, c:0, g:40}
				end
			end
		end
	end
end
