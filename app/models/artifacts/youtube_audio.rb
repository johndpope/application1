module Artifacts
  class YoutubeAudio < Audio
    def save_screenshot(screen_url)
      begin
        file = open(screen_url)
        screen = Screenshot.new
        screen.image = file
        extension = Rack::Mime::MIME_TYPES.invert[screen.image_content_type]
        screen.image_file_name = File.basename(self.id.to_s)[0..-1] + extension
        screen.removable = false
        self.screenshots << screen
        file.close unless file.closed?
        self.screenshots.last
      rescue
        nil
      end
    end
  end
end
