module ImageFilters
	module FwFilters
		class Camerablur::Charlotte < Camerablur
			class << self
				def default_options
					{t:'motion', a:7, r:0}
				end
			end
		end
	end
end
