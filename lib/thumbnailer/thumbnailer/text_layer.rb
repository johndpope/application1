require 'RMagick'
require 'rvg/rvg'

module Thumbnailer
  class TextLayer
    include Magick

    def initialize(width, height, line_count, color, text)
      @width, @height, @line_count, @color, @text = width, height, line_count, color, text
    end

    def render
      rvg = Magick::RVG.new(@width, @height) do |canvas|
        tokens = @text.split(' ')
        @line_count.times do |i|
          phrase = tokens.shift((tokens.count / (@line_count - i).to_f).floor).join(' ')
          line_height = @height / @line_count
          start_y = line_height * i + line_height * 0.75
          font_size = [ @width / phrase.length * 1.8, line_height ].min
          canvas.text(@width / 2, start_y, phrase).styles(text_anchor: 'middle', font_size: font_size,
            fill: @color.to_s, font_family: random_font, font_weight: 'bold', font_style: random_style)
        end
      end
      rvg.draw
    end

    private

      def random_font
        ['Arial', 'Comic Sans', 'Georgia', 'Palatino', 'Times New Roman'].shuffle[0]
      end

      def random_style
        ['normal', 'italic', 'oblique'].shuffle[0]
      end
  end
end