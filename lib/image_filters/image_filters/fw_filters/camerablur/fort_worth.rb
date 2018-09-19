module ImageFilters
	module FwFilters
		class Camerablur::FortWorth < Camerablur
			class << self
				def default_options
					{t:'defocus', a:7, r:0}
				end
			end
		end
	end
end
