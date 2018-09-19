module RmagickTemplates
    class GooglePlusArt10 < SvgTemplate
        # RmagickTemplates::GooglePlusArt10.new(text1: 'Best', text2: 'trucks', text3: 'in the', text4: 'world', subject_image: '/home/master/img1.jpg', background_image: '/home/master/img4.jpg').render.write('/home/master/gpa10.jpg')

        def initialize(options = {})
            @text1 = options[:text1]
            @text2 = options[:text2]
            @text3 = options[:text3]
            @text4 = options[:text4]
            @background_image = options[:background_image]
            @subject_image = options[:subject_image]
        end

        def render
            @background_image0 = @background_image

            images = {
                background_image: [GP_WIDTH, GP_HEIGHT],
                subject_image: [682, 500]
            }

            each_content(%w(text1 text2 text3 text4), images)
        ensure
            FileUtils.rm_rf @tmpl_dir
            @tmpl_dir = nil
        end
    end
end
