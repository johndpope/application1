module ImageFilters
	module HipsterFilters
		class BaseFilter
			def self.call_processor(filter_name, source_file, output_file)
				require ::File.expand_path("../../../lib/hipster_filters/processors/#{filter_name.underscore}_processor", __FILE__)
				"#{filter_name.camelize}Processor".camelize.constantize.new(source_file, output_file).process!
			end
		end
	end
end
