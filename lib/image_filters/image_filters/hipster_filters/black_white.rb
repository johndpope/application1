module ImageFilters
	module HipsterFilters
		class BlackWhite < BaseFilter
			def self.apply(source_file, output_file)
				call_processor(self.name.demodulize.underscore, source_file, output_file)
			end
		end
	end
end
