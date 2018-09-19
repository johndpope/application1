module ImageFilters
	module FwFilters
		# Applies specific filter
		# @abstract
		module Base
			# Calls specific bash script responsible for particular FW Filter
			# @param input_file [String] Path to original image
			# @param output_file [String] Path to output image
			# @param script_name [String] Filename of bash script
			# @param script_opts [Hash] Script options
			#
			def call_script(input_file, output_file, script_name, script_opts = {})
				script_path = File.join(File.expand_path('../../../lib/fw_scripts/',__FILE__), script_name)
				%x{#{script_executor} #{script_path} #{hash_to_cmd_options(script_opts)} "#{input_file}" #{after_infile_params} "#{output_file}"}
			end

			def script_executor
				'sh'
			end

			def after_infile_params
			end

			# Applies filter
			# @param input_file [String] Path to original image
			# @param output_file [String] Path to output image
			# @param opts [Hash] Filter options
			def apply(input_file, output_file, opts = {})
				call_script input_file, output_file, filter_name, filter_opts(default_options, opts)
			end

			# Filters options from the garbage parameters
			# @return [Hash] filtered options
			#
			def filter_opts(defaults = {}, opts = {})
				defaults.merge(opts.select {|k,v| defaults.keys.include?(k)})
			end

			# Converts hash map to commandline options
			# @example hash_to_cmd_options({a:1, b:2, c:3}) -> "-a 1 -b 2 -c 3"
			# @return [String]
			#
			def hash_to_cmd_options(opts = {})
				opts.stringify_keys.map{|k,v|"-#{k} #{v}" unless v.blank?}.join(' ')
			end
		end
	end
end
