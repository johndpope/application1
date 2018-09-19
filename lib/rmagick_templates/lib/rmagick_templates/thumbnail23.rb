module RmagickTemplates
    class Thumbnail23 < SvgTemplate
        # RmagickTemplates::Thumbnail23.new(text0: 'Woodbridge', background_image: '/home/master/img2.jpg', icon: '/home/master/img0.jpg').render.write('/home/master/t23.jpg')

        def initialize(options = {})
            @text0 = options[:text0]
            @background_image = options[:background_image]
            @icon = options[:icon]
        end

        def render
            images = {
                background_image: [T_WIDTH, T_HEIGHT],
                icon: false
            }

            each_content(%w(text0), images)
        ensure
            FileUtils.rm_rf @tmpl_dir

            @tmpl_dir = nil
        end
    end
end
