module PusherService
  class << self
    def deploy_started(sleep_time = 0)
      Setting.get_value_by_name("Utils::PUMA_CHECKER_ENABLED")
      if setting = Setting.find_by_name("Utils::PUMA_CHECKER_ENABLED")
        setting.value = "false"
        setting.save
      end
      minutes_count = sleep_time / 60
      push_message("New release is going to start after #{minutes_count} #{'minute'.pluralize(minutes_count)} at #{(Time.now + sleep_time.seconds).utc}. Please save your changes. After deploy will be finished, you will receive a notification. Thanks.", "Attention!", "default_channel", "deploy_event")
    end

    def deploy_finished
      Setting.get_value_by_name("Utils::PUMA_CHECKER_ENABLED")
      if setting = Setting.find_by_name("Utils::PUMA_CHECKER_ENABLED")
        setting.value = "true"
        setting.save
      end
      push_message("New version of our application was successfully released! You can continue working.", "Attention!", "default_channel", "deploy_event")
    end

    def push_message(message = "", title = "Attention!", channel = "default_channel", event = "default_event")
      tries ||= 10
      Pusher.trigger(channel, event, {message: message, title: title})
    rescue Exception => e
      puts e.message
      sleep 10
      retry unless (tries -= 1).zero?
    else
      puts "Pusher notification executed successfully!"
    end
  end
end
