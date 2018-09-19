module ImageFilters
	module FwFilters
		class Vignette2
			extend Base
			class << self
				SHAPES = %w(rectangle roundrectangle ellipse circle)
				def default_options
					{a:25, d:'90%', s:'roundrectangle', r:'', c:'black', m:'multiply'}
				end

				def filter_name
					'vignette2'
				end

				def random_apply(input_file, output_file)
					opts = {}
					opts[:a] = rand(25..50)
					opts[:d] = rand(80..90)
					opts[:s] = SHAPES.shuffle.first
					apply(input_file, output_file, default_options.merge( opts))
				end
			end
		end
	end
end
