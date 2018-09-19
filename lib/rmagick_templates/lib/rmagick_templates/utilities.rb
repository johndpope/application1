module RmagickTemplates
    module Utilities
        include Magick

        def label(options = {})
            text = options[:text]
            width = options[:width]
            height = options[:height]
            font = options[:font] || pick_font
            color = options[:color] || pick_color

            text_layer = Image.read("label:#{text}") {
                self.background_color = 'transparent'
                self.fill = color
                self.stroke = options[:stroke] || 'white'
                self.stroke_width = 2
                self.font = font
                self.size = "#{width}x#{height}"
                self.gravity = CenterGravity
                self.label = ''
            }[0]

            text_layer
        end

        def pick_font
            available_fonts.values.shuffle.first
        end

        def available_fonts
            fonts_path = File.expand_path('./fonts/*', File.dirname(__FILE__))
            Hash[Dir[fonts_path].map { |f| [ f.scan(/(?<=\/)[^\/]+(?=\.)/).first, f ] }]
        end

        def pick_color
            Magick.colors.shuffle.first.name
        end
    end
end
