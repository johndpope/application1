module ImageFilters
	module InstagramFilters
		class Nashville < BaseFilter
			def self.apply(source_file, output_file)
				call_script source_file, output_file, self.name.demodulize
			end
		end
	end
end
