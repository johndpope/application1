module RmagickTemplates
    class ArtifactsImage3 < SvgTemplate
      # RmagickTemplates::ArtifactsImage3.new(text1: 'Text 1', text2: 'Text 2', text3: 'Text 3', text4: 'Text 4', subject_image: '/home/master/img1.jpg', icon_image: '/home/master/img3.jpg').render.write('/home/master/t1.jpg')

        def initialize(options = {})
            @text1 = options[:text1]
            @text2 = options[:text2]
            @text3 = options[:text3]
            @text4 = options[:text4]
            @icon_image = options[:icon_image]
            @subject_image = options[:subject_image]

        end

        def render
          @subject_image_0 = @subject_image
            images = {
                subject_image:[1654, 1102],
                subject_image_0:[944,1088],
                icon_image:[229, 229]
            }

            each_content(%w(text1 text2 text3 text4), images)
        ensure
            FileUtils.rm_rf @tmpl_dir
            @tmpl_dir = nil
        end
    end
end
