module RmagickTemplates
    class Thumbnail24 < SvgTemplate
        # RmagickTemplates::Thumbnail24.new(text0: 'Youngstown', text1: 'NY', background_image: '/home/master/img2.jpg', icon1: '/home/master/img0.jpg').render.write('/home/master/t24.jpg')

        def initialize(options = {})
            @text0 = options[:text0]
            @text1 = options[:text1]
            @background_image = options[:background_image]
            @icon1 = @icon2 = options[:icon1]
        end

        def render
            images = {
                background_image: [T_WIDTH, T_HEIGHT],
                icon1: false,
                icon2: false
            }

            each_content(%w(text0 text1), images)
        ensure
            FileUtils.rm_rf @tmpl_dir

            @tmpl_dir = nil
        end
    end
end
