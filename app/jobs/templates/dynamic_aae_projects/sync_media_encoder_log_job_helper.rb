# encoding: UTF-8
require 'net/ftp'
module Templates
	module DynamicAaeProjects
		module SyncMediaEncoderLogJobHelper
			SOURCE_FILE = 'Source File'
			OUTPUT_FILE = 'Output File'
			ENCODING_TIME = 'Encoding Time'
			FILE_SUCCESSFULLY_ENCODED = 'File Successfully Encoded'
			ENCODING_FAILED = 'Encoding Failed'

			def self.parse_log(log_file_path)
				res = {}
				log = File.open(log_file_path, "r", &:read)

				cur_daaep_id = nil
				log.each_line do |line|
					if line_key = line.scan(/^\s+-\s+.+:\s+/i).first
						if token = line_key.scan(/^\s+-\s+(.+):\s+/i).flatten.first.to_s.strip
							if [SOURCE_FILE, OUTPUT_FILE, ENCODING_TIME].include? token
								value = line[line_key.length, (line.length-line_key.length)].to_s.strip
								if token == SOURCE_FILE
									daaep_options = project_options value
									unless daaep_options['dynaaepid'].blank?
										cur_daaep_id = daaep_options['dynaaepid'].to_i
										res[cur_daaep_id] = {} unless res.key? cur_daaep_id
										res[cur_daaep_id]['source_file'] = value
									end
								elsif	!cur_daaep_id.blank?
									if token == OUTPUT_FILE
										res[cur_daaep_id]['output_file'] = value
									elsif token == ENCODING_TIME
										res[cur_daaep_id]['encoding_time'] = value.split(':').map { |a| a.to_i }.inject(0) { |a, b| a * 60 + b}
									end
								end
							end
						end
					elsif line_key = line.scan(/^.+\s+:\s+.+/i).first
						if token = line_key.scan(/^.+\s+:\s+(.+)$/i).flatten.first.to_s.strip
							if [FILE_SUCCESSFULLY_ENCODED, ENCODING_FAILED].include?(token) && !cur_daaep_id.blank?
								value = line_key.scan(/^(.+)\s+:\s+.+/i).flatten.first
								res[cur_daaep_id]['encoded_at'] = DateTime.strptime value, '%m/%d/%Y %H:%M:%S %p'
								res[cur_daaep_id]['encoding_succeeded'] = token == (FILE_SUCCESSFULLY_ENCODED ? true : false)
							end
						end
					end
				end
				return res
			end

			def self.project_options(path = '')
	      File.basename(path,File.extname(path)).to_s.split('_').map{|option|
	        parts = option.split('-');
	        parts.length == 2 ? {parts[0] => parts[1]} : {}
	      }.reduce Hash.new, :merge
	    end
		end
	end
end
