module RmagickTemplates
    class Thumbnail2 < SvgTemplate
        # RmagickTemplates::Thumbnail2.new(text0: 'Miami', text1: 'Subject text Subject text', text2: 'Subject text', subject_image: '/home/master/img0.jpg', background_image: '/home/master/img3.jpg').render.write('/home/master/t2.jpg')

        def initialize(options = {})
            @text0 = options[:text0]
            @text1 = options[:text1]
            @text2 = options[:text2]
            @background_image = options[:background_image]
            @subject_image = options[:subject_image]
        end

        def render
            images = {
                background_image: [T_WIDTH, 412],
                subject_image: [442, 382]
            }

            each_content(%w(text0 text1 text2), images)
        ensure
            FileUtils.rm_rf @tmpl_dir
            @tmpl_dir = nil
        end
    end
end
