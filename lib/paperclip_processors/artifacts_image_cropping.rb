module Paperclip
	class ArtifactsImageCropping < Processor
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
			raise Paperclip::Error, "width or height is not set for Artifacts::ImageCropping object" if attachment.instance.width.nil? || attachment.instance.height.nil?
			raise Paperclip::Error, "Artifacts::ImageCropping object is not associated with Artifacts::Image object" if attachment.instance.image.nil?
			raise Paperclip::Error, "Artifacts::Image parent doesn't have image file" unless attachment.instance.image.file.exists?

      geometry = Paperclip::Geometry.from_file(@file)
      filename = [@basename, @current_format || ''].join
      dst = TempfileFactory.new.generate(filename)
			gravity = attachment.instance.image.gravity.nil? ? 'center' : Artifacts::Image::FULL_GRAVITIES[attachment.instance.image.gravity.to_sym].to_s

			begin
				cmd = %Q(convert '#{file.path}' -auto-orient -resize '#{attachment.instance.width}x#{attachment.instance.height}^' -gravity #{gravity} -crop '#{attachment.instance.width}x#{attachment.instance.height}+0+0' +repage '#{dst.path}')
				Paperclip.run(cmd)
			rescue
				raise Paperclip::Error, "There was an error processing the thumbnail for #{@basename}" if @whiny
			end
      dst
    end
	end
end
