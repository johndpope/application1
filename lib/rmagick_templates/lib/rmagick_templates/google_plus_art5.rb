module RmagickTemplates
    class GooglePlusArt5 < SvgTemplate
        # RmagickTemplates::GooglePlusArt5.new(text0: 'california', text1: 'Hillary', text2: 'Presidential', text3: 'Campaign', background_image: '/home/master/img3.jpg').render.write('/home/master/gpa5.jpg')

        def initialize(options = {})
            @text0 = options[:text0]
            @text1 = options[:text1]
            @text2 = options[:text2]
            @text3 = options[:text3]
            @background_image = options[:background_image]
        end

        def render
            images = {
                background_image: [GP_WIDTH, GP_HEIGHT]
            }

            each_content(%w(text0 text1 text2 text3), images)
        ensure
            FileUtils.rm_rf @tmpl_dir
            @tmpl_dir = nil
        end
    end
end
