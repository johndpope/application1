module RmagickTemplates
    class Thumbnail8 < SvgTemplate
        # RmagickTemplates::Thumbnail8.new(text0: 'Location', text1: 'Subject text', text2: 'Subject text', background_image: '/home/master/img2.jpg', subject_image: '/home/master/img4.jpg').render.write('/home/master/t8.jpg')

        def initialize(options = {})
            @text0 = options[:text0]
            @text1 = options[:text1]
            @text2 = options[:text2]
            @background_image = options[:background_image]
            @subject_image = options[:subject_image]
        end

        def render
            images = {
                background_image: [T_WIDTH, T_HEIGHT],
                subject_image: [261, 251]
            }

            each_content(%w(text0 text1 text2), images)
        ensure
            FileUtils.rm_rf @tmpl_dir

            @tmpl_dir = nil
        end
    end
end
