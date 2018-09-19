module RmagickTemplates
    class GooglePlusArt8 < SvgTemplate
        # RmagickTemplates::GooglePlusArt8.new(text1: 'Rehabilitation Services', text2: 'Kindred Hospital', subject_image: '/home/master/img4.jpg').render.write('/home/master/gpa8.jpg')

        def initialize(options = {})
            @text1 = options[:text1]
            @text2 = options[:text2]
            @subject_image = options[:subject_image]
        end

        def render
            images = {
                subject_image: [982, 448]
            }

            each_content(%w(text1 text2), images)
        ensure
            FileUtils.rm_rf @tmpl_dir
            @tmpl_dir = nil
        end
    end
end
