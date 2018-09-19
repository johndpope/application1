module ImageFilters
	module FwFilters
		class Davehilleffect
			extend Base
			class << self
				def default_options
					{b:1, c:0, g:40}
				end

				def filter_name
					'davehilleffect'
				end
			end
		end
	end
end
