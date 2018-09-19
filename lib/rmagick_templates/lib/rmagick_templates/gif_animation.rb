module RmagickTemplates
    class GIFAnimation
        include Magick

        DEFAULT_SPEED = 1.0

        def initialize(options = {})
            @sources = options[:sources] || []
            @speed = options[:speed] || DEFAULT_SPEED
            @width = options[:width] || average_width
            @height = options[:height] || average_height
        end

        def render
            list = ImageList.new
            @sources.each { |s| list << Image.read(s).first.resize_to_fill(@width, @height) }
            list.delay = @speed * 100
            list
        end

        private
        def average_width
            (@sources.map { |s| Image.ping(s).first.columns }.reduce(:+) / @sources.count).to_i
        end

        def average_height
            (@sources.map { |s| Image.ping(s).first.rows }.reduce(:+) / @sources.count).to_i
        end
    end
end
