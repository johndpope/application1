require 'rmagick_templates/utilities'

module RmagickTemplates
    class Collage
        include Magick
        include RmagickTemplates::Utilities

        DEFAULT_WIDTH = 800
        DEFAULT_HEIGHT = 800

        def initialize(options = {})
            @components = options[:components] || []
            @background = options[:background]
            @width = options[:width] || DEFAULT_WIDTH
            @tile = options[:tile]
            @height = options[:height] || DEFAULT_HEIGHT
            @components = @components.map do |c|
                (c.is_a?(File) ? Image.read(c)[0] : c)
            end
            @label_width = @components.select { |c| c.is_a? Image }.map(&:columns).max
            @label_height = @components.select { |c| c.is_a? Image }.map(&:rows).max
            @components = @components.map do |c|
                (!c.is_a?(Image) ? label(text: c.to_s, width: @label_width, height: @label_height) : c)
            end
        end

        def render
            list = ImageList.new { self.label = '' }
            @components.each { |c| list << c }
            tile = @tile
            list.montage {
                self.geometry = '+2+2'
                self.tile = tile
                self.gravity = CenterGravity
                self.background_color = 'transparent'
            }.resize_to_fit(@width, @height)
        end
    end
end
