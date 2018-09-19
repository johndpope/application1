require 'net/ftp'
include Templates::DynamicAaeProjects::SyncMediaEncoderLogJobHelper
module Templates
	module DynamicAaeProjects
		SyncMediaEncoderLogJob = Struct.new(:rendering_machine_name, :rendering_machine_id) do
			TMP_MEDIA_ENCODER_LOG_BASE_DIR = '/tmp/broadcaster/media_encoder/logs'
			FileUtils.mkdir_p TMP_MEDIA_ENCODER_LOG_BASE_DIR

			def perform
				tmp_ame_log_filename = "#{SecureRandom.uuid}.txt"
				tmp_ame_log_fixed_encoding_filename = "#{SecureRandom.uuid}.txt"
				tmp_ame_log_filepath = File.join(TMP_MEDIA_ENCODER_LOG_BASE_DIR, tmp_ame_log_filename)
				tmp_ame_log_fixed_encoding_filepath = File.join(TMP_MEDIA_ENCODER_LOG_BASE_DIR, tmp_ame_log_fixed_encoding_filename)

				begin
					ActiveRecord::Base.transaction do
						rendering_machine = RenderingMachine.find(rendering_machine_id)

						unless rendering_machine.is_active?
							raise "Rendering Machine with ID #{rendering_machine_id} is not active"
						end

						ftp = Net::FTP.new
						ftp.connect(rendering_machine.ip)
						ftp.passive = true
						ftp.login(rendering_machine.user, rendering_machine.password)
						ftp.chdir(rendering_machine.ftp_ame_logs_dir)
						ftp.get(rendering_machine.ftp_ame_log_file_name, tmp_ame_log_filepath, 1024)
						ftp.close

						#converting file encoding from UCS-2LE to utf-8
						%x(iconv -f ucs-2le -t utf-8 "#{tmp_ame_log_filepath}" > "#{tmp_ame_log_fixed_encoding_filepath}")

						log_hash = SyncMediaEncoderLogJobHelper.parse_log(tmp_ame_log_fixed_encoding_filepath)

						Templates::DynamicAaeProject.
							with_target(:sandbox, :distribution).
							where("rendering_time IS NULL OR rendered_at IS NULL OR rendering_succeeded IS NULL").each do |daaep|
								if log_hash.key? daaep.id
									daaep.rendering_time = log_hash[daaep.id]['encoding_time'] if daaep.rendering_time.blank?
									daaep.rendered_at = log_hash[daaep.id]['encoded_at'] if daaep.rendered_at.blank?
									daaep.rendering_succeeded = log_hash[daaep.id]['encoding_succeeded'] if daaep.rendering_succeeded.blank?
									daaep.save!
								end
						end
					end
				rescue Exception => e
					puts e.message
					puts e.backtrace.inspect
					raise e
				ensure
					FileUtils.rm_rf tmp_ame_log_filepath
					FileUtils.rm_rf tmp_ame_log_fixed_encoding_filepath
				end
			end

			def max_attempts
	      5
	    end

			def max_run_time
				300 #seconds
			end

	    def reschedule_at(current_time, attempts)
	      current_time + 10.minutes
	    end

			def success(job)

			end
		end
	end
end
