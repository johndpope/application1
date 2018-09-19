class BotServer < ActiveRecord::Base
  has_many :email_accounts
  validates :name, :path, presence: true
  before_save :touch_recovery_bot_running_status_timestamp

  MAX_GPU_SIZE = 4
  MAX_HDD_SIZE = 4
  LAST_DAYS_KEEP_SYSTEM_LOAD_HISTORY = 30
  SEND_ALERTS_ENABLED = true

  def path
    url = super
    url = "http://" + url if url.present? && !(url.include?("http") || url.include?("https"))
    url
  end

  def save_threads_statistics_json(thread = "active")
    begin
      if self.has_threads_data && thread == "active"
        uri = URI.parse("#{self.path}#{Setting.get_value_by_name('GoogleAccountActivity::ACTIVE_THREADS_STATISTICS_PATH')}")
        http = Net::HTTP.new(uri.host, uri.port)
        http.read_timeout = 15
        http.open_timeout = 15
        response = http.start() {|http|
          http.get(uri.request_uri)
        }
        if response.present? && response.is_a?(Net::HTTPSuccess)
          self.active_threads_data = response.body.to_s.gsub(/\0/, '')
          self.active_threads_updated_at = Time.now
          self.save
        end
      end
    rescue Exception => e
      ActiveRecord::Base.logger.error "Error while grabing bot server statistics: #{e}"
    end
    begin
      if self.has_hardware_data
        uri = URI.parse("#{self.path}#{Setting.get_value_by_name('GoogleAccountActivity::HARDWARE_STATISTICS_PATH')}")
        http = Net::HTTP.new(uri.host, uri.port)
        http.read_timeout = 15
        http.open_timeout = 15
        response = http.start() {|http|
          http.get(uri.request_uri)
        }
        if response.present? && response.is_a?(Net::HTTPSuccess)
          json = JSON.parse(response.body.to_s.gsub(/\0/, ''))
          cpu_array = json.map{|j| j['CPUs'].to_a.map{|e| e['Load'].try(:to_f).try(:round, 0) }}
          cpu = cpu_array.map{|a| (a.inject(:+) / a.length.to_f).round(0)}.to_json
          ram = json.map{|j| j['RAM'].try(:[], 'Load').round(0)}.to_json
          self.last_hour_cpu = cpu
          self.last_hour_ram = ram
          self.hardware_data = json.first.to_s
          self.hardware_data_updated_at = Time.now
          self.save
        end
      end
    rescue Exception => e
      ActiveRecord::Base.logger.error "Error while grabing bot server hardware data: #{e}"
    end
  end

  def hardware_data_json(system_load_period = 24, data = self.hardware_data)
    json_data = eval(data)
    json_text = {}
    (0..0).to_a.each do |e|
      json_text["cpu_name_#{e}"] = json_data['CPUs'].try(:[], e).try(:[], 'Name').to_s
      json_text["cpu_max_clock_#{e}"] = json_data['CPUs'].try(:[], e).try(:[], 'MaxClock').to_s
      json_text["cpu_thermal_design_power_#{e}"] = json_data['CPUs'].try(:[], e).try(:[], 'ThermalDesignPower').to_s
      json_text["cpu_core_voltage_#{e}"] = json_data['CPUs'].try(:[], e).try(:[], 'CoreVoltage').to_s
      json_text["cpu_bus_speed_#{e}"] = json_data['CPUs'].try(:[], e).try(:[], 'BusSpeed').to_s
      json_text["cpu_multiplier_#{e}"] = json_data['CPUs'].try(:[], e).try(:[], 'Multiplier').to_s
      json_text["cpu_base_clock_#{e}"] = json_data['CPUs'].try(:[], e).try(:[], 'BaseClock').to_s
      json_text["cpu_temperatures_#{e}"] = json_data['CPUs'].to_a.map{|e| e['Temperature'].try(:to_f).try(:round, 0) }.join(", ")
      json_text["cpu_clocks_#{e}"] = json_data['CPUs'].to_a.map{|e| e['Clock'] }
      json_text["cpu_loads_#{e}"] = json_data['CPUs'].to_a.map{|e| e['Load'].try(:to_f).try(:round, 0) }.join(", ")
      json_text["cpu_top5_#{e}"] = json_data['CPUs'].try(:[], e).try(:[], 'CPUtop5').to_s
      if system_load_period == 1
        json_text["cpu_last_hour_#{e}"] = self.last_hour_cpu.present? ? eval(self.last_hour_cpu) : []
        json_text["ram_last_hour"] = self.last_hour_ram.present? ? eval(self.last_hour_ram) : []
        json_text["active_threads_last_hour"] = self.last_hour_active_threads.present? ? eval(self.last_hour_active_threads) : []
      else
        empty_values = Array.new(24 * Setting.get_value_by_name("BotServer::LAST_DAYS_KEEP_SYSTEM_LOAD_HISTORY").to_i , -1)
        json_text["cpu_last_hour_#{e}"] = self.cpu_history.present? ? (eval(self.cpu_history) + empty_values).first(system_load_period) : []
        json_text["ram_last_hour"] = self.ram_history.present? ? (eval(self.ram_history) + empty_values).first(system_load_period) : []
        json_text["active_threads_last_hour"] = self.active_threads_history.present? ? (eval(self.active_threads_history) + empty_values).first(system_load_period) : []
      end
    end
    (0..Setting.get_value_by_name("BotServer::MAX_GPU_SIZE").to_i-1).to_a.each do |e|
      json_text["gpu_name_#{e}"] = json_data['GPUs'].try(:[], e).try(:[], 'Name').to_s
      json_text["gpu_temperature_#{e}"] = json_data['GPUs'].try(:[], e).try(:[], 'Temperature').to_s
      json_text["gpu_core_clock_#{e}"] = json_data['GPUs'].try(:[], e).try(:[], 'CoreClock').to_s
      json_text["gpu_memory_clock_#{e}"] = json_data['GPUs'].try(:[], e).try(:[], 'MemoryClock').to_s
      json_text["gpu_shader_clock_#{e}"] = json_data['GPUs'].try(:[], e).try(:[], 'ShaderClock').to_s
      json_text["gpu_core_load_#{e}"] = json_data['GPUs'].try(:[], e).try(:[], 'CoreLoad').to_s
      json_text["gpu_memory_load_#{e}"] = json_data['GPUs'].try(:[], e).try(:[], 'MemoryLoad').to_s
      json_text["gpu_video_engine_load_#{e}"] = json_data['GPUs'].try(:[], e).try(:[], 'VideoEngineLoad').to_s
      json_text["gpu_memory_control_load_#{e}"] = json_data['GPUs'].try(:[], e).try(:[], 'MemoryControlLoad').to_s
      json_text["gpu_gpu_fan_speed_#{e}"] = json_data['GPUs'].try(:[], e).try(:[], 'GpuFan').try(:first).try(:[], 'Speed').to_s
      json_text["gpu_fan_control_#{e}"] = json_data['GPUs'].try(:[], e).try(:[], 'FanControl').to_s
      json_text["gpu_boose_core_clock_#{e}"] = json_data['GPUs'].try(:[], e).try(:[], 'BooseCoreClock').to_s
      json_text["gpu_max_core_clock_#{e}"] = json_data['GPUs'].try(:[], e).try(:[], 'MaxCoreClock').to_s
      json_text["gpu_max_memory_cock_#{e}"] = json_data['GPUs'].try(:[], e).try(:[], 'MaxMemoryCock').to_s
      json_text["gpu_memory_size_#{e}"] = json_data['GPUs'].try(:[], e).try(:[], 'MemorySize').to_s
      json_text["gpu_memory_bandwidth_#{e}"] = json_data['GPUs'].try(:[], e).try(:[], 'MemoryBandwidth').to_s
      json_text["gpu_driver_version_#{e}"] = json_data['GPUs'].try(:[], e).try(:[], 'DriverVersion').to_s
      json_text["gpu_shaders_#{e}"] = json_data['GPUs'].try(:[], e).try(:[], 'Shaders').to_s
      json_text["gpu_pixel_rate_#{e}"] = json_data['GPUs'].try(:[], e).try(:[], 'PixelRate').to_s
      json_text["gpu_texture_rate_#{e}"] = json_data['GPUs'].try(:[], e).try(:[], 'TextureRate').to_s
      json_text["gpu_tdp_#{e}"] = json_data['GPUs'].try(:[], e).try(:[], 'TDP').to_s
      json_text["gpu_bus_width_#{e}"] = json_data['GPUs'].try(:[], e).try(:[], 'BusWidth').to_s
    end
    json_text["mainboard_name"] = json_data['MainBoard'].try(:[], 'Name').to_s
    json_text["mainboard_vbat"] = json_data['MainBoard'].try(:[], 'VBat').to_s
    json_text["mainboard_temperature"] = json_data['MainBoard'].try(:[], 'Temperature').to_s
    json_text["mainboard_chip_set"] = json_data['MainBoard'].try(:[], 'ChipSet').to_s
    json_text["mainboard_south_bridge"] = json_data['MainBoard'].try(:[], 'SouthBridge').to_s
    (0..Setting.get_value_by_name("BotServer::MAX_HDD_SIZE").to_i-1).to_a.each do |e|
      json_text["hdd_name_#{e}"] = json_data['HDDs'].try(:[], e).try(:[], 'Name').to_s
      json_text["hdd_temperature_#{e}"] = json_data['HDDs'].try(:[], e).try(:[], 'Temperature').to_s
      json_text["hdd_used_space_#{e}"] = json_data['HDDs'].try(:[], e).try(:[], 'UsedSpace').to_s
      json_text["hdd_total_space_#{e}"] = json_data['HDDs'].try(:[], e).try(:[], 'TotalSpace').to_s
    end
    json_text["ram_load"] = json_data['RAM'].try(:[], 'Load').to_s
    json_text["ram_used_memory"] = json_data['RAM'].try(:[], 'UsedMemory').to_s
    json_text["ram_available_memory"] = json_data['RAM'].try(:[], 'AvailableMemory').to_s
    json_text["ram_top5"] = json_data['RAM'].try(:[], 'RAMtop5').to_s
    json_text["ram_cas_latency"] = json_data['RAM'].try(:[], 'CASLatency').to_s
    json_text["ram_ras_to_cas_delay"] = json_data['RAM'].try(:[], 'RASToCASDelay').to_s
    json_text["ram_ras_precharge"] = json_data['RAM'].try(:[], 'RASPrecharge').to_s
    json_text["ram_tras"] = json_data['RAM'].try(:[], 'TRAS').to_s
    json_text["ram_frequency"] = json_data['RAM'].try(:[], 'Frequency').to_s
    json_text["net_status_upload"] = json_data['NetStatus'].try(:[], 'Upload').to_s
    json_text["net_status_download"] = json_data['NetStatus'].try(:[], 'Download').to_s
    json_text["net_status_host_ip"] = json_data['NetStatus'].try(:[], 'HostIP').to_s
    json_text["net_status_host_name"] = json_data['NetStatus'].try(:[], 'HostName').to_s
    json_text["net_status_mac_address"] = json_data['NetStatus'].try(:[], 'MacAddress').to_s
    json_text["net_status_public_ip"] = json_data['NetStatus'].try(:[], 'PublicIP').to_s
    json_text["net_status_os_version"] = json_data['NetStatus'].try(:[], 'OsVersion').to_s
    json_text["net_status_net_use_of_cpu_process"] = json_data['NetStatus'].try(:[], 'NetUseOfCpuProcess').to_s
    json_text.each_key {|key| json_text[key] = '-' if json_text[key] == '-1.0'}
    json_text.to_json
  end

  def save_last_hour_hw_statistics
    if self.hardware_data_updated_at.present? && self.hardware_data_updated_at > Time.now - 1.hour
      cpu = eval(self.last_hour_cpu.to_s)
      ram = eval(self.last_hour_ram.to_s)
      cpu_history_array = eval(self.cpu_history.to_s)
      ram_history_array = eval(self.ram_history.to_s)
      if cpu.is_a?(Array) && ram.is_a?(Array) && cpu.size > 0 && ram.size > 0
        cpu_history_array = [] unless cpu_history_array.is_a?(Array)
        ram_history_array = [] unless ram_history_array.is_a?(Array)
        cpu_history_array.unshift((cpu.sum / cpu.size).to_i)
        ram_history_array.unshift((ram.sum / ram.size).to_i)
        system_load_history_limit = 24 * Setting.get_value_by_name("BotServer::LAST_DAYS_KEEP_SYSTEM_LOAD_HISTORY").to_i
        self.cpu_history = cpu_history_array.first(system_load_history_limit).to_s
        self.ram_history = ram_history_array.first(system_load_history_limit).to_s
        self.save
      end
    end
  end

  def save_last_hour_active_threads_statistics
    if self.active_threads_updated_at.present? && self.active_threads_updated_at > Time.now - 1.hour
      last_hour_active_threads_array = eval(self.last_hour_active_threads.to_s)
      active_threads_history_array = eval(self.active_threads_history.to_s)
      if last_hour_active_threads_array.is_a?(Array) && last_hour_active_threads_array.size > 0
        active_threads_history_array = [] unless active_threads_history_array.is_a?(Array)
        active_threads_history_array.unshift((last_hour_active_threads_array.sum / last_hour_active_threads_array.size).to_i)
        system_load_history_limit = 24 * Setting.get_value_by_name("BotServer::LAST_DAYS_KEEP_SYSTEM_LOAD_HISTORY").to_i
        self.active_threads_history = active_threads_history_array.first(system_load_history_limit).to_s
        self.save
      end
    end
  end

  def save_active_threads_statistics
    last_hour_active_threads_array = eval(self.last_hour_active_threads.to_s)
    last_hour_active_threads_array = [] unless last_hour_active_threads.present?
    threads_load = if self.active_threads_updated_at.present? && self.active_threads_updated_at > Time.now - 1.minute
      json = JSON.parse(self.active_threads_data)
      active_threads = json["active_threads"].to_i
      maximum_threads = json["maximum_threads"].to_i
      (active_threads * 100 / maximum_threads).to_i
    else
      -1
    end
    last_hour_active_threads_array.unshift(threads_load)
    self.last_hour_active_threads = last_hour_active_threads_array.first(60).to_s
    self.save
  end

  def clear_daily_activity_queue
    puts "clear_daily_activity_queue"
    gaa_ids = GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]]).where("bot_servers.id = ? AND google_account_activities.linked IS NOT TRUE", self.id).references(google_account:[email_account:[:bot_server]]).pluck(:id)
    GoogleAccountActivity.where("id in (?)", gaa_ids).update_all({linked: true, updated_at: Time.now - 2.days}) if gaa_ids.present?
  end

  def turn_daily_activity(enable = true)
    if enable
      self.daily_activity_enabled = true
      self.recovery_bot_running_status = true
      self.recovery_accounts_activity_enabled = true
    else
      self.daily_activity_enabled = false
      self.recovery_bot_running_status = false
      self.recovery_accounts_activity_enabled = false
    end
  end

  def kill_zenno
    if Rails.env.production?
      if self.daily_activity_enabled && self.is_zenno_running?
        kill_zenno_response = Utils.http_get("#{self.path}/kill_zenno.php", {}, 3, 10).try(:body).to_s
        ActiveRecord::Base.logger.info "Kill Zenno response: #{kill_zenno_response}"
        BotServer.where(id: self.id).update_all(daily_activity_enabled: false, recovery_bot_running_status: false, recovery_accounts_activity_enabled: false, recovery_accounts_batch_activity_enabled: false, recovery_answers_checker_enabled: false)
        sleep 10
        if self.is_zenno_running?
          if Setting.get_value_by_name("BotServer::SEND_ALERTS_ENABLED").to_s == "true"
            Utils.pushbullet_broadcast("Failed to kill Zenno", "Failed to kill Zenno on '#{self.name}'.")
            BroadcasterMailer.zenno_kill(self.name, false)
          end
        else
          if Setting.get_value_by_name("BotServer::SEND_ALERTS_ENABLED").to_s == "true"
            Utils.pushbullet_broadcast("Successfully killed Zenno", "Successfully killed Zenno on '#{self.name}'.")
            BroadcasterMailer.zenno_kill(self.name, true)
          end
        end
      else
        if self.daily_activity_enabled
          BotServer.where(id: self.id).update_all(daily_activity_enabled: false, recovery_bot_running_status: false, recovery_accounts_activity_enabled: false, recovery_accounts_batch_activity_enabled: false, recovery_answers_checker_enabled: false)
        end
      end
    end
  end

  def is_zenno_running?
    checker_response = Net::HTTP.get_response(URI.parse("#{self.path}/check_zenno.php"))
    if checker_response.is_a?(Net::HTTPSuccess)
      if checker_response.body.to_s.include?("No tasks are running")
        false
      elsif checker_response.body.to_s.include?("ZennoPoster.exe")
        true
      else
        nil
      end
    else
      nil
    end
  end

  def start_zenno
    if Rails.env.production?
      #self.clear_daily_activity_queue
      tries = 5
      begin
        zenno_running = self.is_zenno_running?
        if zenno_running.nil?
          Utils.pushbullet_broadcast("Failed to execute Zenno start script", "Failed to execute Zenno start script on '#{self.name}'.")
        else
          unless zenno_running
            raise "Didn't executed"
          else
            #executed successfully
            self.turn_daily_activity(true)
            self.save
            Utils.pushbullet_broadcast("Zenno was successfully started", "Zenno was successfully started on '#{self.name}'")
            GoogleAccountActivity.fields_updater([self], true)
          end
        end
      rescue
        ActiveRecord::Base.logger.info "Failed to start Zenno on '#{self.name}' at #{Time.now}, tries left: #{tries}"
        unless (tries -= 1).zero?
          sleep 60
          retry
        else
          self.turn_daily_activity(false)
          self.save
          Utils.pushbullet_broadcast("Can't start Zenno", "Failed to start Zenno on '#{self.name}'")
        end
      end
    end
  end

  class << self
    def kill_all_zenno
      BotServer.all.each do |bot_server|
        bot_server.kill_zenno
      end
    end

    def by_id(id)
      return all unless id.present?
      where('bot_servers.id = ?', id.strip)
    end

    def by_name(name)
      return all unless name.present?
      where('lower(bot_servers.name) like ?', "%#{name.downcase}%")
    end

    def save_statistics_from_all_servers
      BotServer.all.each do |bot_server|
        bot_server.save_threads_statistics_json
      end
    end

    def save_statistics_cron
      if Rails.env.production?
        self.save_statistics_from_all_servers
        BotServer.all.each do |bot_server|
          bot_server.save_active_threads_statistics
        end
      end
    end

    def save_system_load_history
      BotServer.all.each do |bot_server|
        bot_server.save_last_hour_hw_statistics
        bot_server.save_last_hour_active_threads_statistics
      end
    end
  end

  private
    def touch_recovery_bot_running_status_timestamp
      self.recovery_bot_running_status_updated_at = Time.now if self.recovery_bot_running_status_changed?
    end
end
