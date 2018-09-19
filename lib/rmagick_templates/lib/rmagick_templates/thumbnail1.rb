module RmagickTemplates
    class Thumbnail1 < SvgTemplate
        # RmagickTemplates::Thumbnail1.new(text0: 'New York', text1: 'National', text2: 'Protection', text3: 'speech', subject_image: '/home/master/img1.jpg', background_image: '/home/master/img3.jpg').render.write('/home/master/t1.jpg')

        def initialize(options = {})
            @text0 = options[:text0]
            @text1 = options[:text1]
            @text2 = options[:text2]
            @text3 = options[:text3]
            @background_image = options[:background_image]
            @subject_image = options[:subject_image]
        end

        def render
            @background_image0 = @background_image

            images = {
                background_image: [T_WIDTH, T_HEIGHT],
                background_image0: [T_WIDTH, T_HEIGHT],
                subject_image: [500, 500]
            }

            each_content(%w(text0 text1 text2 text3), images)
        ensure
            FileUtils.rm_rf @tmpl_dir
            @tmpl_dir = nil
        end
    end
end
