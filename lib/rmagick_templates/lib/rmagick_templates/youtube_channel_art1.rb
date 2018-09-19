module RmagickTemplates
    class YoutubeChannelArt1 < SvgTemplate
        # RmagickTemplates::YoutubeChannelArt1.new(text1: 'Kindred Hospital', text2: 'Rehabilitation Services', background_image: '/home/master/img2.jpg').render.write('/home/master/yca1.jpg')

        def initialize(options = {})
            @text1 = options[:text1]
            @text2 = options[:text2]
            @background_image = options[:background_image]
        end

        def render
            @background_image0 = @background_image1 = @subject_image = @background_image

            images = {
                background_image: [YCA_WIDTH, YCA_HEIGHT],
                background_image0: [YCA_WIDTH, YCA_HEIGHT],
                background_image1: [YCA_WIDTH, YCA_DESKTOP_HEIGHT],
                subject_image: [514, YCA_DESKTOP_HEIGHT]
            }

            each_content(%w(text1 text2), images)
        ensure
            FileUtils.rm_rf @tmpl_dir
            @tmpl_dir = nil
        end
    end
end
