module RmagickTemplates
    class GooglePlusArt9 < SvgTemplate
        # RmagickTemplates::GooglePlusArt9.new(text0: 'florida', text1: 'Kliemann Bros', text2: 'Oficial', text3: 'channel', subject_image: '/home/master/img0.jpg', background_image: '/home/master/img2.jpg').render.write('/home/master/gpa9.jpg')

        def initialize(options = {})
            @text0 = options[:text0]
            @text1 = options[:text1]
            @text2 = options[:text2]
            @text3 = options[:text3]
            @background_image = options[:background_image]
            @subject_image = options[:subject_image]
        end

        def render
            @background_image0 = @background_image

            images = {
                background_image: [GP_WIDTH, GP_HEIGHT],
                background_image0: [GP_WIDTH, GP_HEIGHT],
                subject_image: [1078, 677]
            }

            each_content(%w(text0 text1 text2 text3), images)
        ensure
            FileUtils.rm_rf @tmpl_dir
            @tmpl_dir = nil
        end
    end
end
