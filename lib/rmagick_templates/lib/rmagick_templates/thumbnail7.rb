module RmagickTemplates
    class Thumbnail7 < SvgTemplate
        # RmagickTemplates::Thumbnail7.new(text0: 'Washington', text1: 'Subject text', text2: 'Subject text', background_image: '/home/master/img4.jpg', subject_image: '/home/master/img2.jpg').render.write('/home/master/t7.jpg')

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
                subject_image: [462, 632]
            }

            each_content(%w(text0 text1 text2), images)
        ensure
            FileUtils.rm_rf @tmpl_dir

            @tmpl_dir = nil
        end
    end
end
