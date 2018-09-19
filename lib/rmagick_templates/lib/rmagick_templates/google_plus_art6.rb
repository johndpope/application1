module RmagickTemplates
    class GooglePlusArt6 < SvgTemplate
        # RmagickTemplates::GooglePlusArt6.new(text0: 'FLORIDA', text1: 'Hillary&apos;s Campaign', text2: 'Kick-off Trip', background_image: '/home/master/img4.jpg').render.write('/home/master/gpa6.jpg')

        def initialize(options = {})
            @text0 = options[:text0]
            @text1 = options[:text1]
            @text2 = options[:text2]
            @background_image = options[:background_image]
        end

        def render
            @subject_image = @background_image

            images = {
                background_image: [GP_WIDTH, GP_HEIGHT],
                subject_image: [338, 488]
            }

            each_content(%w(text0 text1 text2), images)
        ensure
            FileUtils.rm_rf @tmpl_dir
            @tmpl_dir = nil
        end
    end
end
