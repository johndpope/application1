module RmagickTemplates
    class TextMask
        include Magick
        include RmagickTemplates::Utilities
        # extend RmagickTemplates::Utilities

        DEFAULTS = {
            background: 'xc:transparent',
            fill: 'xc:white',
            text: "#{('A'..'Z').to_a.join}\n#{('a'..'z').to_a.join}\n#{('0'..'9').to_a.join}",
            width: 640,
            height: 480,
            v_pad: 10,
            h_pad: 10
        }

        def initialize(options = {})
            @layout = DEFAULTS.merge(options.select { |k, v| ![nil, ''].include?(v) })
            @viewport_width = @layout[:width] - @layout[:h_pad] * 2
            @viewport_height = @layout[:height] - @layout[:v_pad] * 2
        end

        def render
            Image.read(@layout[:background])[0].resize_to_fill(@layout[:width], @layout[:height]).composite(
                label(text: @layout[:text], font: @layout[:font], width: @viewport_width, height: @viewport_height).composite(
                    Image.read(@layout[:fill])[0].resize_to_fill(@viewport_width, @viewport_height),
                    CenterGravity,
                    SrcInCompositeOp
                ),
                CenterGravity,
                SrcOverCompositeOp
            )
        end
    end
end
