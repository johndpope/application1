module Paperclip
    class GoogleAvatar < Processor
        def initialize file, options = {}, attachment = nil
            super
            @file = file
            @instance = options[:instance]
            @current_format   = File.extname(@file.path)
            @whiny = options[:whiny].nil? ? true : options[:whiny]
            @basename = File.basename(file.path, File.extname(file.path))
        end

        def make
          geometry = Paperclip::Geometry.from_file(@file)
          filename = [@basename, @current_format || ''].join
          dst = TempfileFactory.new.generate(filename)

          begin
              cmd = ImagemagickScripts::squareup width: 250, height: 250, input: file.path, output: dst.path
              success = Paperclip.run(cmd)
          rescue PaperclipCommandLineError
            raise PaperclipError, "There was an error processing the thumbnail for #{@basename}" if whiny
          end

          dst
        end
    end
end
