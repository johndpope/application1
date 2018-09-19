module ImageFilters
	module FwFilters
		class Colorcells::Louisville < Colorcells
			class << self
				def default_options
					{n:'10x10', c:'', p:100, s:'200x300', d:'100,100'}
				end
			end
		end
	end
end
