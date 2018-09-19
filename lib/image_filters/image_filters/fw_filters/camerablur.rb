module ImageFilters
	module FwFilters
		class Camerablur
			extend Base
			class << self
				def default_options
					{t:'defocus', a:10, r:0}
				end

				def filter_name
					'camerablur'
				end
			end
		end
	end
end
