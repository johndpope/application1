module ImageFilters
	module FwFilters
		class Colorcells
			extend Base
			class << self
				def default_options
					{n:'8x8', c:'', p:50, s:'200,300', d:'70,70'}
				end

				def filter_name
					'colorcells'
				end

				def script_executor
					'bash'
				end
			end
		end
	end
end
