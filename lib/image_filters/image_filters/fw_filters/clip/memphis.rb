module ImageFilters
	module FwFilters
		class Clip::Memphis < Clip
			class << self
				def default_options
					{c:'i', l:100, h:100}
				end
			end
		end
	end
end
