module ImageFilters
	module FwFilters
		class Crosshatch::Fresno < Crosshatch
			class << self
				def default_options
					{l:7, s:10, g:1, a:1, e:'dark'}
				end
			end
		end
	end
end
