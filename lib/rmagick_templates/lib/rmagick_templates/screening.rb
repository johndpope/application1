module RmagickTemplates
    class Screening
        include Magick

        DEFAULTS = { background: 'xc:transparent', screen: 'xc:transparent', width: 640, height: 480 }

        def initialize(options = {})
            @layout = DEFAULTS.merge(options)
        end

        def render
            Image.read(@layout[:background])[0].resize_to_fill(@layout[:width], @layout[:height]).composite(
                Image.read(@layout[:screen])[0].resize_to_fill(@layout[:width], @layout[:height]),
                SouthGravity,
                LuminizeCompositeOp
            )
        end
    end
end
