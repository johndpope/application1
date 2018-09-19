require 'rmagick_templates/utilities'

module RmagickTemplates
	class YoutubeChannelArt
		include Magick
		include RmagickTemplates::Utilities

		CANVAS_WIDTH = 2560
		CANVAS_HEIGHT = 1440
		SAFE_AREA_WIDTH = 1546
		SAFE_AREA_HEIGHT = 423
		SAFE_AREA_X_OFFSET = (CANVAS_WIDTH - SAFE_AREA_WIDTH) / 2
		SAFE_AREA_Y_OFFSET = (CANVAS_HEIGHT - SAFE_AREA_HEIGHT) / 2

		def initialize(options = {})
			@background = Image.read(options[:background])[0]
			@background_avg_color = @background.resize(1, 1).pixel_color(1, 1)
			@slogan = options[:slogan] || ' '
			@thumbnail = options[:thumbnail]
			@thumbnail_abbr = options[:thumbnail_abbr]
			@thumbnail_abbr = nil if @thumbnail_abbr == ''
			@thumbnail_gravity = options[:thumbnail_gravity].try(:to_sym) == :west ? WestGravity : EastGravity
			@slogan_gravity = @thumbnail_gravity == WestGravity ? EastGravity : WestGravity

			if @thumbnail
				@slogan_width = (SAFE_AREA_WIDTH * 0.75).to_i
				@thumbnail_width = (SAFE_AREA_WIDTH * 0.25).to_i
			else
				@slogan_width = SAFE_AREA_WIDTH
			end
		end

		def render(options = {})
			out = @background.resize_to_fill(CANVAS_WIDTH, CANVAS_HEIGHT, CenterGravity)
			text_color = @background_avg_color.contrast

			slogan_layer = label(text: @slogan, color: text_color, width: @slogan_width, height: SAFE_AREA_HEIGHT)

			safe_layer = if @thumbnail
				Image.read('xc:transparent') {
					self.size = "#{SAFE_AREA_WIDTH}x#{SAFE_AREA_HEIGHT}"
				}[0]
				.composite(slogan_layer, @slogan_gravity, OverCompositeOp)
				.composite(build_thumbnail, @thumbnail_gravity, XorCompositeOp)
			else
				slogan_layer
			end

			out = out.composite(
				safe_layer.sigmoidal_contrast_channel,
				SAFE_AREA_X_OFFSET,
				SAFE_AREA_Y_OFFSET,
				OverCompositeOp
			)

			slogan_layer.destroy!
			safe_layer.destroy!

			out
		end

		def build_thumbnail
			image = Image.read(@thumbnail) { self.background_color = 'transparent' }[0]
			image.resize_to_fit!(@thumbnail_width, SAFE_AREA_HEIGHT)

			out = image

			if @thumbnail_abbr
				abbr_width = (@thumbnail_width * 0.5).to_i
				abbr_height = (SAFE_AREA_HEIGHT * 0.5).to_i

				color = @background_avg_color.to_color
				abbr = label(text: @thumbnail_abbr, color: color, stroke: color, width: abbr_width, height: abbr_height)

				out = out.composite(abbr, CenterGravity, XorCompositeOp)
				abbr.destroy!
			end
			# image.destroy!
			out
		end
	end
end
