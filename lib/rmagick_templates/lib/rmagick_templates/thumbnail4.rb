module RmagickTemplates
    class Thumbnail4 < SvgTemplate
        # RmagickTemplates::Thumbnail4.new(text0: 'Iraq', text1: 'Obama speech about war', subject_image1: '/home/master/img0.jpg', subject_image2: '/home/master/img1.jpg', subject_image3: '/home/master/img4.jpg', subject_image4: '/home/master/img3.jpg', background_image: '/home/master/img2.jpg').render.write('/home/master/t4.jpg')

        def initialize(options = {})
            @text0 = options[:text0]
            @text1 = options[:text1]
            @background_image = options[:background_image]
            @subject_image1 = options[:subject_image1]
            @subject_image2 = options[:subject_image2]
            @subject_image3 = options[:subject_image3]
            @subject_image4 = options[:subject_image4]
        end

        def render
            @background_image0 = @background_image

            images = {
                background_image: [T_WIDTH, T_HEIGHT],
                background_image0: [T_WIDTH, T_HEIGHT],
                subject_image1: [291, 238],
                subject_image2: [272, 282],
                subject_image3: [530, 514],
                subject_image4: [405, 622]
            }

            each_content(%w(text0 text1), images)
        ensure
            FileUtils.rm_rf @tmpl_dir
            @tmpl_dir = nil
        end
    end
end
