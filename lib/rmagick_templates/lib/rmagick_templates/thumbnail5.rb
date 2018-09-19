module RmagickTemplates
    class Thumbnail5 < SvgTemplate
        # RmagickTemplates::Thumbnail5.new(text0: 'Location', text1: 'Subject text', subject_image1: '/home/master/img0.jpg', subject_image2: '/home/master/img1.jpg', subject_image3: '/home/master/img2.jpg', logo: '/home/master/img3.jpg').render.write('/home/master/t5.jpg')

        def initialize(options = {})
            @text0 = options[:text0]
            @text1 = options[:text1]
            @subject_image1 = options[:subject_image1]
            @subject_image2 = options[:subject_image2]
            @subject_image3 = options[:subject_image3]
            @logo = options[:logo]
        end

        def render
            images = {
                subject_image1: [856, 716],
                subject_image2: [420, 292],
                subject_image3: [419, 290],
                logo: [317, 296]
            }

            each_content(%w(text0 text1), images)
        ensure
            FileUtils.rm_rf @tmpl_dir

            @tmpl_dir = nil
        end
    end
end
