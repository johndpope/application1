module RmagickTemplates
    class Thumbnail9 < SvgTemplate
        # RmagickTemplates::Thumbnail9.new(text0: 'Location', text1: 'SUBJECT TEXT', subject_image: '/home/master/img2.jpg', logo: '/home/master/img1.jpg').render.write('/home/master/t9.jpg')

        def initialize(options = {})
            @text0 = options[:text0]
            @text1 = options[:text1]
            @subject_image = options[:subject_image]
            @logo = options[:logo]
        end

        def render
            images = {
                subject_image: [1120, T_HEIGHT],
                logo: [195, 175]
            }

            each_content(%w(text0 text1), images)
        ensure
            FileUtils.rm_rf @tmpl_dir

            @tmpl_dir = nil
        end
    end
end
