module RmagickTemplates
    class YoutubeChannelArt4 < SvgTemplate
        # RmagickTemplates::YoutubeChannelArt4.new(text1: 'Kliemann Bros', text2: 'Bros Kliemann', background_image: '/home/master/img1.jpg').render.write('/home/master/yca4.jpg')

        def initialize(options = {})
            @text1 = options[:text1]
            @text2 = options[:text2]
            @background_image = options[:background_image]
        end

        def render
            images = {
                background_image: [1462, YCA_DESKTOP_HEIGHT]
            }

            each_content(%w(text1 text2), images)
        ensure
            FileUtils.rm_rf @tmpl_dir
            @tmpl_dir = nil
        end
    end
end
