module RmagickTemplates
    class YoutubeChannelArt8 < SvgTemplate
        # RmagickTemplates::YoutubeChannelArt8.new(text1: 'Rehabilitation Services', text2: 'Kindred Hospital', background_image: '/home/master/img4.jpg').render.write('/home/master/yca8.jpg')

        def initialize(options = {})
            @text1 = options[:text1]
            @text2 = options[:text2]
            @background_image = options[:background_image]
        end

        def render
            images = {
                background_image: [1548, YCA_DESKTOP_HEIGHT]
            }

            each_content(%w(text1 text2), images)
        ensure
            FileUtils.rm_rf @tmpl_dir
            @tmpl_dir = nil
        end
    end
end
