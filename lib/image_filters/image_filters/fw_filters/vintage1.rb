module ImageFilters
	module FwFilters
		class Vintage1
			extend Base
			VIGNETTE_SHAPES = %w(roundrectangle horizontal vertical)
			BORDER_TYPES = %w(torn rounded)
			class << self
				def default_options
					{b:10, c:-20, s:'roundrectangle', r:20, l:0, N:30, L:25, B:30, M:35, T:'', W:5, R:10, C:'white'}
				end

				def filter_name
					'vintage1'
				end

				def random_apply(input_file, output_file)
					opts = {}
					opts[:s] = ['',VIGNETTE_SHAPES].flatten.shuffle.first
					opts[:T] = ['', BORDER_TYPES].flatten.shuffle.first
					opts[:R] = 2

					apply(input_file, output_file, default_options.merge(opts))
				end

				def after_infile_params
					file_list = Dir[File.expand_path('../../../lib/assets/textures/**/*.jpg', __FILE__)]
					file_list.shuffle.first
				end
			end
		end
	end
end
