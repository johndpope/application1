module ImageFilters
	module FwFilters
		class Coloration::NashvilleDavidson < Coloration
			class << self
				def default_options
					{h:240, s:75, l:0, u: 'degrees', r: 29.9, g: 58.7, b:11.4, B:10, C:-10}
				end
			end
		end
	end
end
