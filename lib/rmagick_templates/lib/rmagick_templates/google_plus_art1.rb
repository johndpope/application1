module RmagickTemplates
    class GooglePlusArt1 < SvgTemplate
        # RmagickTemplates::GooglePlusArt1.new(text1: 'Kindred', text2: 'Hospital', text3: 'Rehabilitation', text4: 'Services', background_image: '/home/master/img4.jpg').render.write('/home/master/gpa1.jpg')

        def initialize(options = {})
            @text1 = options[:text1]
            @text2 = options[:text2]
            @text3 = options[:text3]
            @text4 = options[:text4]
            @background_image = options[:background_image]
        end

        def render
            @background_image0 = @subject_image = @background_image

            images = {
                background_image: [GP_WIDTH, GP_HEIGHT],
                background_image0: [GP_WIDTH, GP_HEIGHT],
                subject_image: [660, 672]
            }

            each_content(%w(text1 text2 text3 text4), images)
        ensure
            FileUtils.rm_rf @tmpl_dir
            @tmpl_dir = nil
        end
    end
end
