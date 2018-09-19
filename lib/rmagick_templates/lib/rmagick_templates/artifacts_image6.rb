module RmagickTemplates
    class ArtifactsImage6 < SvgTemplate
      # RmagickTemplates::ArtifactsImage6.new(text1: 'Text 1', subject_image: '/home/master/img1.jpg', icon_image: '/home/master/img3.jpg').render.write('/home/master/t1.jpg')

        def initialize(options = {})
            @text1 = options[:text1]
            @icon_image = options[:icon_image]
            @subject_image = options[:subject_image]

        end

        def render
            images = {
                subject_image:[1942,1103],
                icon_image:[225,264]
            }

            each_content(%w(text1), images)
        ensure
            FileUtils.rm_rf @tmpl_dir
            @tmpl_dir = nil
        end
    end
end
