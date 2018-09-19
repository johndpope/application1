module RmagickTemplates
    class Thumbnail20 < SvgTemplate
        # RmagickTemplates::Thumbnail20.new(text0: 'Delaware Valley', text1: 'T', text2: 'X', background_image: '/home/master/img2.jpg', icon: '/home/master/img0.jpg').render.write('/home/master/t20.jpg')

        def initialize(options = {})
            @text0 = options[:text0]
            @text1 = @text3 = options[:text1]
            @text2 = @text4 = options[:text2]
            @background_image = options[:background_image]
            @icon = options[:icon]
        end

        def render
            images = {
                background_image: [T_WIDTH, T_HEIGHT],
                icon: false
            }

            each_content(%w(text0 text1 text2 text3 text4), images)
        ensure
            FileUtils.rm_rf @tmpl_dir

            @tmpl_dir = nil
        end
    end
end
