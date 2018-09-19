module RmagickTemplates
    class Thumbnail30 < SvgTemplate
        # RmagickTemplates::Thumbnail30.new(text0: 'Location', text1: 'TX', background_image: '/home/master/img2.jpg', icon: '/home/master/img0.jpg').render.write('/home/master/t30.jpg')

        def initialize(options = {})
            @text0 = options[:text0]
            @text1 = options[:text1]
            @background_image = options[:background_image]
            @icon = options[:icon]
        end

        def render
            images = {
                background_image: [T_WIDTH, T_HEIGHT],
                icon: false
            }

            each_content(%w(text0 text1), images)
        ensure
            FileUtils.rm_rf @tmpl_dir

            @tmpl_dir = nil
        end
    end
end
