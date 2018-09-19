module Paperclip
	class AspectCropProcessorGenerator
		CROP_HEIGHT = 200
		CROP_WIDTH = 400
		QUALITY = 8

		def self.generate(cropping_layout, gravity)
			clazz = Object.const_set("#{cropping_layout.camelize}#{gravity.camelize}", Class.new(Processor))

			clazz.class_eval do
				def initialize file, options = {}, attachment = nil
					super
					class_parts = self.class.to_s.split(/(?=[A-Z])/)
					@file = file
					@instance = options[:instance]
					@convert_options = options[:convert_options]
					@current_format = File.extname(@file.path)
					@whiny = options[:whiny].nil? ? true : options[:whiny]
					@basename = File.basename(file.path, File.extname(file.path))
					@cropping_layout = class_parts[0].to_s.downcase
					@gravity = class_parts[1].to_s.downcase
				end

				def make
					geometry = Paperclip::Geometry.from_file(@file)
					filename = [@basename, @current_format || ''].join
					dst = TempfileFactory.new.generate(filename)
					crop_side_1 = CROP_WIDTH
					crop_side_2 = CROP_HEIGHT
					size = case @cropping_layout
						when 'square'; "#{crop_side_1}x#{crop_side_1}";
						when 'horizontal'; "#{crop_side_1}x#{crop_side_2}";
						when 'vertical'; "#{crop_side_2}x#{crop_side_1}";
						else "#{crop_side_1}x#{crop_side_1}"
					end

					begin
						cmd = ImagemagickScripts::aspect_crop_cmd file.path, dst.path, size, Artifacts::Image::FULL_GRAVITIES[@gravity.to_sym].to_s, QUALITY
						success = Paperclip.run(cmd)
					rescue Paperclip::Error
						raise "There was an error processing the thumbnail for #{@basename}" if @whiny
					end

					dst
				end
			end

			clazz
		end
	end
end
