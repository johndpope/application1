module ImageFilters
	module FwFilters
		# Applies a bevel effect to border of an image.
		class Bevelborder
			extend Base
			class << self
				def default_options
					{s:'', b:'', m:'outer', p:50, c:50, a:25, t:'hardlight'}
				end

				def filter_name
					'bevelborder'
				end
			end
		end
	end
end
