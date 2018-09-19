module ImageFilters
	module InstagramFilters
		class BaseFilter
			def self.call_script(source_file, output_file, filter)
				FileUtils.mkdir_p ImageFilters::ROOT_DIR
				tmp_file_name = SecureRandom.hex
				tmp_file_ext = File.extname source_file
				tmp_file_path = File.join(ImageFilters::ROOT_DIR, "#{tmp_file_name}#{tmp_file_ext}")

				FileUtils.cp_r source_file, tmp_file_path
				begin
					%x{cd #{::File.expand_path("../../../lib/instagram_filters", __FILE__)} && python instagram_filters.py -i #{tmp_file_path} -f #{filter.demodulize}}
					%x{convert #{tmp_file_path} #{output_file}}
				rescue Exception => e
					raise e
				ensure
					FileUtils.rm_f tmp_file_path
				end
			end
		end
	end
end
