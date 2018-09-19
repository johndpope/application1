module RmagickTemplates
    class Thumbnail11 < SvgTemplate
        # RmagickTemplates::Thumbnail11.new(text0: 'Location', text1: 'Subject text', text2: 'here', background_image1: '/home/master/img2.jpg', background_image2: '/home/master/img3.jpg', subject_image: '/home/master/img0.jpg').render.write('/home/master/t11.jpg')

        def initialize(options = {})
            @text0 = options[:text0]
            @text1 = options[:text1]
            @text2 = options[:text2]
            @background_image1 = options[:background_image1]
            @background_image2 = options[:background_image2]
            @subject_image = options[:subject_image]
        end

        def render
            images = {
                background_image1: [T_WIDTH, T_HEIGHT],
                background_image2: [T_WIDTH, T_HEIGHT],
                subject_image: [360, 360]
            }

            each_content(%w(text0 text1 text2), images)
        ensure
            FileUtils.rm_rf @tmpl_dir

            @tmpl_dir = nil
        end
    end
end
