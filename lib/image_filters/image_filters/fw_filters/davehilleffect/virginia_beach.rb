module ImageFilters
	module FwFilters
		class Davehilleffect::VirginiaBeach < Davehilleffect
			class << self
				def default_options
					{b:1, c:0, g:70}
				end
			end
		end
	end
end
