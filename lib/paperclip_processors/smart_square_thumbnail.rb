module Paperclip
  class SmartSquareThumbnail < Processor
    def initialize file, options = {}, attachment = nil
      super
      @file = file
      @instance = options[:instance]
      @current_format   = File.extname(@file.path)
      @whiny = options[:whiny].nil? ? true : options[:whiny]
      @basename = File.basename(file.path, File.extname(file.path))
			@geometry = options[:geometry]
    end

    def make
      geometry = Paperclip::Geometry.from_file(@file)
      filename = [@basename, @current_format || ''].join
      dst = TempfileFactory.new.generate(filename)

			begin
				ImagemagickScripts::smart_crop(@geometry, file.path).write(dst.path){self.quality = 72}
			rescue PaperclipCommandLineError
				raise PaperclipError, "There was an error processing the thumbnail for #{@basename}" if @whiny
			end

      dst
    end
  end
end
