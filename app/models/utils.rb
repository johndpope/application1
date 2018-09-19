require 'rubygems'
require 'selenium-webdriver'
class Utils
	START_BUSINESS_WORKING_HOUR = 6
	END_BUSINESS_WORKING_HOUR = 27
  PUMA_CHECKER_ENABLED = true
  PUSHBULLET_RECEIVERS = "serghei.topor@gmail.com,admin@excelmanufacturing.co.uk,black3mamba@gmail.com,zavorotnii@gmail.com,tmriordan@gmail.com"
  EMAIL_RECEIVERS = "serghei.topor@gmail.com,black3mamba@gmail.com,zavorotnii@gmail.com,tmriordan@gmail.com"
  NAS_TOTAL_SIZE = "13.6T"
  NAS_ALERT_PERCENTAGE_START = 90
  NAS_SHUTDOWN_BOTS_PERCENTAGE = 95
  DATABASE_ALERT_PERCENTAGE_START = 85
  DATABASE_SHUTDOWN_BOTS_PERCENTAGE = 95
  DELAYED_JOB_SERVERS = "10.50.50.244,10.50.50.93,10.50.50.94"
	def self.parse_date(date_str)
		begin
			date = Date.strptime(date_str,'%b/%d/%Y')
			return date
		rescue
		end

		begin
			date = Date.strptime(date_str,'%m/%d/%Y')
			return date
		rescue
		end

		begin
			date = Date.strptime(date_str,'%b-%d-%Y')
			return date
		rescue
		end

		return nil
	end

	def self.is_ascii(str)
    str.each_byte {|c| return false if c>=128}
    true
	end

	def self.shortify(str,length)
		return (str.nil? || str.length<=length+3 ? str : str[0,length-1])
	end

	def self.shortify_file_name(file_name)
		min_length = 50;
    if(file_name.nil? || file_name.length<=min_length + 3)
      return file_name
    else
      return "#{file_name[0,min_length-1]}...#{File.extname(file_name)}"
    end
	end

	def self.titleize(str)
		return str.split(/\s+/).map{|word| word.slice(0,1).capitalize + word.slice(1..-1)}.join(' ') if str
	end

	def self.open_for_business?(exclude_weekend = true, now = Time.now, bot_server = nil)
		return false if exclude_weekend && (now.saturday? || now.sunday?)
    t1, t2 = nil
    if bot_server.present?
      t1 = bot_server.start_business_working_hour*60*60
      t2 = bot_server.end_business_working_hour*60*60
    else
      t1 = Setting.get_value_by_name("Utils::START_BUSINESS_WORKING_HOUR").to_i*60*60
      t2 = Setting.get_value_by_name("Utils::END_BUSINESS_WORKING_HOUR").to_i*60*60
    end

		t_now = now.hour*60*60 + now.min*60 + now.sec
		if t_now < t1 && t_now < (t2 - 24*60*60)
			true
		else
			t_now.between?(t1,t2)
		end
	end

	def self.internal_ip
		%x(echo $(ifconfig eth0 | awk -F: '/inet addr:/ {print $2}' | awk '{ print $1 }')).strip
	end

  # def self.count_sentences(text)
  #   text = text.to_s
  #   text = text.squish
  #   arr = text.mb_chars.split(/(?:\.|\?|\!)(?= [^a-z]|$)/).size
  # end
  #
  # def self.smart_truncate_sentences(text, sentence_limit)
  #   text = text.to_s
  #   text = text.squish
  #   arr = text.mb_chars.split(/(?:\.|\?|\!)(?= [^a-z]|$)/)
  #   arr = arr[0...sentence_limit]
  #   new_text = arr.join(".")
  #   new_text += '.'
  # end

  def self.smart_sentences_count(s)
    s.split(/\.(\s|$)+/).reject { |c| c.blank? }.size
  end

  def self.smart_sentences_truncate(s, sentences)
    #check for '!' in the end of sentences
    s.split(/\.(\s|$)+/).reject { |c| c.blank? }.first(sentences).map{|s| s.strip}.join('. ') + '.'
  end

  def self.seconds_to_time(total_seconds, with_seconds = false)
    #alternative: Time.at(total_seconds).utc.strftime("%H:%M:%S")
    if total_seconds.present?
      seconds = total_seconds % 60
      minutes = (total_seconds / 60) % 60
      hours = total_seconds / 3600
      if with_seconds
        format("%02d:%02d:%02d", hours, minutes, seconds)
      else
        #round minutes
        minutes += 1 if seconds >= 30
        format("%02d:%02d", hours, minutes)
      end
    end
  end

  def self.http_get(url, params = {}, tries = 1, sleep_time = 0)
    uri = URI.parse(url)
    uri.query = URI.encode_www_form(params)
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 60
    http.open_timeout = 60
    response = http.start() {|http|
      http.get(uri.request_uri)
    }
  rescue Exception => e
    ActiveRecord::Base.logger.info "Get request failed to #{uri.to_s} at #{Time.now}"
    ActiveRecord::Base.logger.info e.message
    unless (tries -= 1).zero?
      sleep sleep_time
      retry
    end
  end

  def self.delayed_jobs_checker
    Setting.get_value_by_name("Utils::DELAYED_JOB_SERVERS").split(",").map(&:strip).each_with_index do |dj_server_ip, index|
      response = %x(ssh broadcaster@#{dj_server_ip} "pwd")
      unless response.present?
        Utils.pushbullet_broadcast("Delayed jobs server ##{index+1}- connection failed", "Can't connect to delayed jobs server on IP: #{dj_server_ip} at #{Time.now.utc}.")
      end
    end
  end

  def self.puma_checker
    if Rails.env.production? && Setting.get_value_by_name("Utils::PUMA_CHECKER_ENABLED") == "true"
      logger ||= Logger.new("#{Rails.root}/log/puma_checker.log", 10, 100.megabytes)
      tries ||= 2
      begin
        response = http_get(Rails.configuration.routes_default_url_options[:host])
        if [4,5].include?(response.code.to_i / 100) || response.body.include?("something went wrong") || response.body.include?("504 Gateway Time-out") || response.body.include?("502 Bad Gateway")
          raise 'An error has occured'
        end
      rescue Exception => e
        unless (tries -= 1).zero?
          sleep 10
          retry
        else
          now = Time.now
          #stop puma
          begin
            %x(ssh broadcaster@10.50.50.247 "cd /home/broadcaster/broadcaster/current && ( export RACK_ENV='production' ; ~/.rvm/bin/rvm default do bundle exec pumactl -S /home/broadcaster/broadcaster/shared/tmp/pids/puma.state stop)")
            sleep 5
            #start puma
            %x(ssh broadcaster@10.50.50.247 "cd /home/broadcaster/broadcaster/current && ( export RACK_ENV='production' ; ~/.rvm/bin/rvm default do bundle exec puma -C /home/broadcaster/broadcaster/shared/puma.rb --daemon )")
          rescue
            logger.info("Puma failed to restart at: #{now}")
          end
          logger.info("Puma restarted at: #{now}")
          Utils.pushbullet_broadcast("Broadcaster's puma web server restarted", "Puma web server was restarted at #{now.utc}, because cron job detected it doesn't respond to requests.")
        end
      end
    end
  end

  def self.db_storage_alert
    begin
      Net::SSH.start("10.50.50.246", "broadcaster") do |ssh|
        result = ssh.exec!("df -h")
        ssh.close
        database_hdds = result.to_s.split("\n").map {|x| x.split(" ")}
        database_hdds.shift
        database_hdds.reject! {|x| !x[0].include?("/")}
        if database_hdds.present?
          if database_hdds[0][4].to_i >= Setting.get_value_by_name("Utils::DATABASE_SHUTDOWN_BOTS_PERCENTAGE").to_i
            Utils.pushbullet_broadcast("Database Space Alert", "Use space is #{database_hdds[0][4]}. All bot servers were shutdown.")
            BotServer.kill_all_zenno
            BroadcasterMailer.db_storage_alert
          elsif database_hdds[0][4].to_i >= Setting.get_value_by_name("Utils::DATABASE_ALERT_PERCENTAGE_START").to_i
            Utils.pushbullet_broadcast("Database Space Alert", "Use space is #{database_hdds[0][4]}")
          end
        end
      end
    rescue
      Utils.pushbullet_broadcast("Database alert", "Can't connect to Database server at: #{Time.now}")
    end
  end

  def self.nas_storage_alert
    begin
      Net::SSH.start("10.50.50.16", "broadcaster") do |ssh|
        result = ssh.exec!("zfs list -p")
        result = result.split("\n").second.split("\s")
        ssh.close
        nas_used_space = result[1].to_i + result[3].to_i
        nas_available_space = result[2].to_i
        nas_total_space = nas_used_space + nas_available_space
        nas_use_percentage = ((nas_used_space / nas_total_space.to_f) * 100).to_i
        if nas_use_percentage >= Setting.get_value_by_name("Utils::NAS_ALERT_PERCENTAGE_START").to_i
          Utils.pushbullet_broadcast("NAS storage alert", "NAS storage used space is #{nas_use_percentage}%!\nUsed: #{number_to_human_size(nas_used_space)}\nAvailable: #{number_to_human_size(nas_available_space)}\nTotal: #{number_to_human_size(nas_total_space)}")
          if nas_use_percentage >= Setting.get_value_by_name("Utils::NAS_SHUTDOWN_BOTS_PERCENTAGE").to_i
            BotServer.kill_all_zenno
            BroadcasterMailer.nas_storage_alert
          end
        end
      end
    rescue
      Utils.pushbullet_broadcast("NAS alert", "Can't connect to NAS server at: #{Time.now.utc}")
    end
  end

  def self.pushbullet_broadcast(title, body)
    Setting.get_value_by_name("Utils::PUSHBULLET_RECEIVERS").split(",").map(&:strip).each do |receiver|
      begin
        Pushbullet::Push.create_note(receiver, title, body)
      rescue
        ActiveRecord::Base.logger.info "Failed to send pushbullet notification at: #{Time.now.utc}"
      end
    end
  end

  def self.save_web_screenshot(target, url, width = 1600, height = 1200)
    begin
      file_name = "#{Time.now.to_i}_#{target.class.name.tableize}_#{target.id}"
      file_path = "/tmp/#{file_name}.png"
      options = Selenium::WebDriver::Firefox::Options.new(args: ['-headless'])
      driver = Selenium::WebDriver.for :firefox, options: options
      driver.manage.window.size = Selenium::WebDriver::Dimension.new(width, height)
      driver.navigate.to url
      sleep 5
      driver.save_screenshot(file_path)
      driver.quit
      f = File.open(file_path)
      screen = Screenshot.new
      screen.image = f
      screen.action_type = "web_screenshot"
      extension = Rack::Mime::MIME_TYPES.invert[screen.image_content_type]
      screen.image_file_name = File.basename(target.id.to_s)[0..-1] + extension
      screen.removable = false
      target.screenshots << screen
      f.close
      %x(rm -rf #{file_path})
    rescue Exception => e
      ActiveRecord::Base.logger.error "Error in save_web_screenshot at #{Time.now.utc}: #{e}"
    end
  end
end
