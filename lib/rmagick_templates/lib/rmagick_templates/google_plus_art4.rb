module RmagickTemplates
    class GooglePlusArt4 < SvgTemplate
        # RmagickTemplates::GooglePlusArt4.new(text1: 'Kliemann', text2: 'Bros', text3: 'Oficial', text4: 'channel', background_image: '/home/master/img0.jpg').render.write('/home/master/gpa4.jpg')

        def initialize(options = {})
            @text1 = options[:text1]
            @text2 = options[:text2]
            @text3 = options[:text3]
            @text4 = options[:text4]
            @background_image = options[:background_image]
        end

        def render
            images = {
                background_image: [915, 688]
            }

            each_content(%w(text1 text2 text3 text4), images)
        ensure
            FileUtils.rm_rf @tmpl_dir
            @tmpl_dir = nil
        end
    end
end
