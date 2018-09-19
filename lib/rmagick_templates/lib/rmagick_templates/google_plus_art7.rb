module RmagickTemplates
    class GooglePlusArt7 < SvgTemplate
        # RmagickTemplates::GooglePlusArt7.new(text1: 'Top Secret', text2: 'Deer Scents', subject_image: '/home/master/img1.jpg', background_image: '/home/master/img0.jpg').render.write('/home/master/gpa7.jpg')

        def initialize(options = {})
            @text1 = options[:text1]
            @text2 = options[:text2]
            @background_image = options[:background_image]
            @subject_image = options[:subject_image]
        end

        def render
            @background_image0 = @background_image

            images = {
                background_image: [GP_WIDTH, GP_HEIGHT],
                background_image0: [GP_WIDTH, GP_HEIGHT],
                subject_image: [750, 390]
            }

            each_content(%w(text1 text2), images)
        ensure
            FileUtils.rm_rf @tmpl_dir
            @tmpl_dir = nil
        end
    end
end
