module ImageFilters
	module FwFilters
		class Sketchetch::Bakersfield < Sketchetch
			class << self
				def default_options
					{m:'normal', e:4}
				end
			end
		end
	end
end
