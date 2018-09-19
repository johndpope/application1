module RmagickTemplates
    class GooglePlusArt2 < SvgTemplate
        # RmagickTemplates::GooglePlusArt2.new(text: 'Obama oficial chanel', subject_image1: '/home/master/img1.jpg', subject_image2: '/home/master/img3.jpg', subject_image3: '/home/master/img0.jpg', background_image: '/home/master/img2.jpg').render.write('/home/master/gpa2.jpg')

        def initialize(options = {})
            @text = options[:text]
            @background_image = options[:background_image]
            @subject_image1 = options[:subject_image1]
            @subject_image2 = options[:subject_image2]
            @subject_image3 = options[:subject_image3]
        end

        def render
            @background_image0 = @background_image

            images = {
                background_image: [GP_WIDTH, GP_HEIGHT],
                background_image0: [GP_WIDTH, GP_HEIGHT],
                subject_image1: [308, 356],
                subject_image2: [308, 356],
                subject_image3: [308, 356]
            }

            each_content(%w(text), images)
        ensure
            FileUtils.rm_rf @tmpl_dir
            @tmpl_dir = nil
        end
    end
end
