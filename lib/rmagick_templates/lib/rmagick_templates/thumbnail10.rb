module RmagickTemplates
    class Thumbnail10 < SvgTemplate
        # RmagickTemplates::Thumbnail10.new(text0: 'Location', text1: 'Subject', text2: 'text', text3: 'here', background_image: '/home/master/img2.jpg', subject_image1: '/home/master/img0.jpg', subject_image2: '/home/master/img4.jpg').render.write('/home/master/t10.jpg')

        def initialize(options = {})
            @text0 = options[:text0]
            @text1 = options[:text1]
            @text2 = options[:text2]
            @text3 = options[:text3]
            @background_image = options[:background_image]
            @subject_image1 = options[:subject_image1]
            @subject_image2 = options[:subject_image2]
        end

        def render
            @background_image0 = @background_image

            images = {
                background_image: [T_WIDTH, T_HEIGHT],
                background_image0: [T_WIDTH, T_HEIGHT],
                subject_image1: [1020, T_HEIGHT],
                subject_image2: [434, 428]
            }

            each_content(%w(text0 text1 text2 text3), images)
        ensure
            FileUtils.rm_rf @tmpl_dir

            @tmpl_dir = nil
        end
    end
end
