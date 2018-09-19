module TmpFolderCleaner
	class << self
		#TODO: refactor code: search files by content-type instead of extension
		def clean
	    info_log ||= Logger.new("#{Rails.root}/log/tmp_folder_cleaner.log")
	    info_log.info("Tmp cleaner started at: #{Time.now}")
			%w(jpg jpeg gif png svg mp4 tar).each do |ext|
				%x(find /tmp -maxdepth 1 -type f -iname "*.#{ext}" -mmin +90 -delete)
			end

			%x(find /tmp -maxdepth 1 -type f -iname "open-uri*" -mmin +90 -delete)
	    info_log.info("Tmp cleaner finished at: #{Time.now}")
			nil
		end

		def clean_image_magick_files
			info_log ||= Logger.new("#{Rails.root}/log/tmp_folder_cleaner.log")
	    info_log.info("Temporary ImageMagick files cleaning started at: #{Time.now}")

			%x(find /tmp -maxdepth 1 -type f -name "magick-*" -delete)

			info_log.info("Temporary ImageMagick files cleaning finished at: #{Time.now}")
			nil
		end
	end
end
