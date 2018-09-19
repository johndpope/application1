module Thumbnailer
  class Color
    def initialize(r, g, b)
      @r, @g, @b = r, g, b
    end

    def to_s
      str = code.to_s(16)
      '#' + '0' * (6 - str.length) + str
    end

    def triadic_correlation
      [ Color.new(@b, @r, @g), Color.new(@g, @b, @r) ]
    end

    def contrasts
      offset = 0xffffff / 3
      contrast_codes = [ code + offset, code + offset * 2 ].map { |e| e > 0xffffff ? e - 0xffffff : e }
      contrast_codes.sort.map { |e| Color.new(e / 0x10000, (e % 0x10000) / 0x100, e % 0x100) }
    end

    private

      def code
        @r * 0x10000 + @g * 0x100 + @b
      end
  end
end