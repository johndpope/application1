module RmagickTemplates
    class OutlineMask
        include Magick

        DEFAULTS = {
            background: 'xc:transparent',
            fill: 'xc:white',
            outline: 'xc:black',
            width: 640,
            height: 480,
            v_pad: 10,
            h_pad: 10
        }

        def initialize(options = {})
            @layout = DEFAULTS.merge(options.delete_if { |k, v| v == nil || v == '' })
            @viewport_width = @layout[:width] - @layout[:h_pad] * 2
            @viewport_height = @layout[:height] - @layout[:v_pad] * 2
        end

        def render
            Image.read(@layout[:background])[0].resize_to_fill(@layout[:width], @layout[:height]).composite(
                Image.read(@layout[:outline])[0].resize_to_fit(@viewport_width, @viewport_height).composite(
                    Image.read(@layout[:fill])[0].resize_to_fill(@viewport_width, @viewport_height),
                    CenterGravity,
                    SrcInCompositeOp
                ),
                CenterGravity,
                OverCompositeOp
            )
        end
    end
end
