module RmagickTemplates
    class Thumbnail3 < SvgTemplate
        # RmagickTemplates::Thumbnail3.new(text0: 'Detroit', text1: 'Subject text Subject text', subject_image1: '/home/master/img0.jpg', subject_image2: '/home/master/img1.jpg', subject_image3: '/home/master/img4.jpg', background_image: '/home/master/img3.jpg').render.write('/home/master/t3.jpg')

        def initialize(options = {})
            @text0 = options[:text0]
            @text1 = options[:text1]
            @background_image = options[:background_image]
            @subject_image1 = options[:subject_image1]
            @subject_image2 = options[:subject_image2]
            @subject_image3 = options[:subject_image3]
        end

        def render
            @background_image0 = @background_image

            images = {
                background_image: [T_WIDTH, T_HEIGHT],
                background_image0: [T_WIDTH, T_HEIGHT],
                subject_image1: [460, 424],
                subject_image2: [460, 424],
                subject_image3: [460, 424]
            }

            each_content(%w(text0 text1), images)
        ensure
            FileUtils.rm_rf @tmpl_dir
            @tmpl_dir = nil
        end
    end
end
