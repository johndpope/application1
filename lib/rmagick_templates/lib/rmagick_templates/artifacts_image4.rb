module RmagickTemplates
    class ArtifactsImage4 < SvgTemplate
      # RmagickTemplates::ArtifactsImage4.new(text1: 'Text 1', text2: 'Text 2', subject_image: '/home/master/img1.jpg', icon_image: '/home/master/img3.jpg').render.write('/home/master/t1.jpg')

        def initialize(options = {})
            @text1 = options[:text1]
            @text2 = options[:text2]
            @icon_image = options[:icon_image]
            @subject_image = options[:subject_image]

        end

        def render
            images = {
                subject_image:[1920,1080],
                icon_image:[274, 274]
            }

            each_content(%w(text1 text2), images)
        ensure
            FileUtils.rm_rf @tmpl_dir
            @tmpl_dir = nil
        end
    end
end
