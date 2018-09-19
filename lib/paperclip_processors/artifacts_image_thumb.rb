module Paperclip
	class ArtifactsImageThumb < Processor
		HEIGHT = 320
		WIDTH = 320
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

			cmd = if file.content_type != 'image/svg+xml'
							gravity = attachment.instance.gravity.nil? ? 'center' : Artifacts::Image::FULL_GRAVITIES[attachment.instance.gravity.to_sym].to_s
							%Q(convert '#{file.path}' -auto-orient -resize '#{WIDTH}x#{HEIGHT}^' -gravity 'center' -crop '#{WIDTH}x#{HEIGHT}+0+0' +repage '#{dst.path}')
						else
							%Q(rsvg-convert -a -w #{WIDTH} -h #{HEIGHT} -f svg '#{file.path}' -o '#{dst.path}')
						end
			Paperclip.run(cmd)

      dst
    end
	end
end
