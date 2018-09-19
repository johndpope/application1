require 'cgi'
require 'fileutils'
require 'pg'
require 'RMagick'
require_relative 'text_layer'
require_relative 'color'

module Thumbnailer

  class Generator

    include Magick

    CASE_TYPE_ICONS_URL_BASE = "http://legalbistro.com/files/case_types_images/"

    def initialize(output_dir, case_type, locality)
      @output_dir = output_dir            
      @case_type  = case_type
      @locality = locality

      @mutex = Mutex.new
    end

    def generate
      FileUtils.mkdir(@output_dir) unless File.directory?(@output_dir)
      
      layout = layouts.shuffle[0]
      r, g, b = rand(0xff), rand(0xff), rand(0xff)
      color = Thumbnailer::Color.new(r, g, b)
      contrasts = color.contrasts
      base_layer = Image.new(layout[:base][:width], layout[:base][:height]) do
        self.background_color = "#{color.to_s}"
      end
      case_type_layer = load_case_icon.scale(layout[:case_type][:width], layout[:case_type][:height])
      
      pitch = pitches(@case_type.name).shuffle[0]
      pitch_layer = TextLayer.new(
        layout[:pitch][:width],
        layout[:pitch][:height],
        layout[:pitch][:line_count],
        contrasts[0],
        pitch
      ).render

      location = "#{@locality.name}, #{@locality.primary_region.name}"
      location_layer = TextLayer.new(
        layout[:location][:width],
        layout[:location][:height],
        layout[:location][:line_count],
         contrasts[1],
        location
      ).render

      out = base_layer
      .composite(case_type_layer, layout[:case_type][:x], layout[:case_type][:y], OverCompositeOp)
      .composite(pitch_layer, layout[:pitch][:x], layout[:pitch][:y], OverCompositeOp)
      .composite(location_layer, layout[:location][:x], layout[:location][:y], OverCompositeOp)

      icon_name = "#{@output_dir}/#{@case_type.name}_#{@locality.name}_#{@locality.primary_region.name}.png".downcase      
      out.write(icon_name)
      [ base_layer, case_type_layer, pitch_layer, location_layer, out ].each { |e| e.destroy! }              
    end

    private

      def load_case_icon                  
          normalized_name = @case_type.name.gsub(' ', '%20').gsub('"', '%22')
          full_url = "#{CASE_TYPE_ICONS_URL_BASE}#{normalized_name}.png"          
          return Image.read(full_url)[0]        
      end
      
      def pitches(case_type_name)
        [
          "When lawyers compete, you win",
          "Lawyers compete for your business",
          "Lawyers for your business",
          "Online lawyers for your business",
          "Best lawyers for you",
          "Best lawyers for your business",
          "The Best Lawyers in USA",
          # "Super Lawyers",
          "Legal Advice for You",
          "Online Lawyers Advice",
          "#{case_type_name} Lawyers for You",
          "Present your case to a good lawyer",
          "Best Lawyers Here",
          "Find the best lawyer"
        ]
      end

      def layouts
        [
          {
            base: { width: 1000, height: 575 },
            case_type: { width: 400, height: 400, x: 30, y: 30 },
            location: { width: 900, height: 175, x: 50, y: 400, line_count: 1 },
            pitch: { width: 500, height: 325, x: 450, y: 50, line_count: 3 }
          },
          {
            base: { width: 1000, height: 575 },
            case_type: { width: 400, height: 400, x: 575, y: 30 },
            location: { width: 900, height: 175, x: 50, y: 400, line_count: 1 },
            pitch: { width: 500, height: 325, x: 50, y: 50, line_count: 3 }
          },
          {
            base: { width: 1000, height: 575 },
            case_type: { width: 400, height: 400, x: 30, y: 150 },
            location: { width: 900, height: 175, x: 50, y: 0, line_count: 1 },
            pitch: { width: 500, height: 325, x: 450, y: 200, line_count: 3 }
          },
          {
            base: { width: 1000, height: 575 },
            case_type: { width: 400, height: 400, x: 575, y: 150 },
            location: { width: 900, height: 175, x: 50, y: 0, line_count: 1 },
            pitch: { width: 500, height: 325, x: 50, y: 200, line_count: 3 }
          }
        ]
      end
  end
end
