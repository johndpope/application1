module RenderingMachineService
	TMP_RENDERING_MACHINES_BASE_DIR = '/tmp/broadcaster/rendering_machines'
	RENDERING_MACHINE_SERVICE_LOG = Rails.root.join('log','services','rendering_machines.log')

	def self.schedule_video_sets(rendering_machine_id, client_id, limit)
		logger ||= Logger.new(RENDERING_MACHINE_SERVICE_LOG, 10, 100.megabytes)
		in_watch_folder_limit = 0
		in_queue_limit = 40

		ftp = Net::FTP.new
		begin
			rendering_machine = RenderingMachine.find(rendering_machine_id)
			client = Client.find(client_id)
			if client.source_videos_available_for_distribution.exists?
				ftp.connect(rendering_machine.ip)
				ftp.passive = true
				ftp.login(rendering_machine.user, rendering_machine.password)
				ftp.chdir(rendering_machine.ftp_broadcaster_aae_projects_dir)
				in_queue = ftp.nlst('*').to_a.length
				ftp.chdir(rendering_machine.ftp_watch_folder_dir)
				in_watch_folder = ftp.nlst('*.aepx').to_a.length

				if in_watch_folder == in_watch_folder_limit && in_queue <= in_queue_limit
					ActiveRecord::Base.transaction do
						logger.info "Creating Random Video Set ..."
						logger.info "Rendering Machine ID: #{rendering_machine_id}"
						logger.info "Client ID: #{client_id}"
						1.upto(limit){BlendedVideoService.create_random_blended_video rendering_machine, client}
					end
				end
			end
		rescue Exception => e
			logger.fatal "Video Set Scheduling Failed ..."
			logger.fatal "Client ID: #{client_id}"
			logger.fatal "Rendering Machine ID: #{rendering_machine_id}"
			logger.fatal e.message
			logger.fatal e.backtrace.inspect
		ensure
			begin
				ftp.close
			rescue Exception => ex
			end
		end
	end

	def self.get_info(rendering_machine_id)
		FileUtils.mkdir_p TMP_RENDERING_MACHINES_BASE_DIR
		tmp_info_filename = "#{SecureRandom.uuid}.yml"
		tmp_info_filepath = File.join(TMP_RENDERING_MACHINES_BASE_DIR, tmp_info_filename)

		info = {id: rendering_machine_id,
			is_accessible: true,
			in_watch_folder: nil,
			in_queue: nil,
			in_watch_folder_output: nil,
			available_disk_space: nil,
			total_disk_space: nil}
		rendering_machine = RenderingMachine.find(rendering_machine_id)
		ftp = nil
		begin
			ftp = rendering_machine.ftp_connection
			ftp.chdir(rendering_machine.ftp_broadcaster_dir)
			ftp.get(rendering_machine.info_file_name, tmp_info_filepath, 1024)
			info_yaml = YAML::load(File.read(tmp_info_filepath))
			info[:total_disk_space] = info_yaml[:total_disc_space]
			info[:available_disk_space] = info_yaml[:available_disc_space]

			ftp.chdir(rendering_machine.ftp_watch_folder_output_dir)
			info[:in_watch_folder_output] = ftp.nlst('*.mp4').to_a.length
			info[:in_watch_folder] = info_yaml[:in_watch_folder]
			info[:in_queue] = info_yaml[:in_queue]
		rescue Exception => e
			if e.is_a?(Errno::EHOSTUNREACH)
				info[:is_accessible] = false
			end
		ensure
			begin; ftp.close; rescue Exception => ex; end
			FileUtils.rm_rf tmp_info_filepath
			return info
		end
	end

	def self.get_infos
		res = {}
		RenderingMachine.order(:id).each do |rm|
			res[rm.id] = get_info(rm.id)
		end
		return res
	end

	def self.sync_infos
		RenderingMachine.all.each do |rm|
			ActiveRecord::Base.transaction do
				rm.update_attributes get_info(rm.id)
			end
		end
	end
end
