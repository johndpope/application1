module ImageFilters
	module FwFilters
		class Clip
			extend Base
			class << self
				def default_options
					{c:'i', l:'0.1%', h:'0.1%'}
				end

				def filter_name
					'clip'
				end
			end
		end
	end
end
