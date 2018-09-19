module RmagickTemplates
    class Thumbnail6 < SvgTemplate
        # RmagickTemplates::Thumbnail6.new(text0: 'Washington', text1: 'Subject text Subject text', text2: 'Subject text', subject_image1: '/home/master/img2.jpg', subject_image2: '/home/master/img0.jpg', subject_image3: '/home/master/img1.jpg', subject_image4: '/home/master/img3.jpg').render.write('/home/master/t6.jpg')

        def initialize(options = {})
            @text0 = options[:text0]
            @text1 = options[:text1]
            @text2 = options[:text2]
            @subject_image1 = options[:subject_image1]
            @subject_image2 = options[:subject_image2]
            @subject_image3 = options[:subject_image3]
            @subject_image4 = options[:subject_image4]
        end

        def render
            images = {
                subject_image1: [427, 404],
                subject_image2: [412, 488],
                subject_image3: [419, 488],
                subject_image4: [424, 297]
            }

            each_content(%w(text0 text1 text2), images)

        ensure
            FileUtils.rm_rf @tmpl_dir

            @tmpl_dir = nil
        end
    end
end
