module RmagickTemplates
    class YoutubeChannelArt5 < SvgTemplate
        # RmagickTemplates::YoutubeChannelArt5.new(text0: 'california', text1: 'Hillary', text2: 'Presidential', text3: 'Campaign', background_image: '/home/master/img4.jpg').render.write('/home/master/yca5.jpg')

        def initialize(options = {})
            @text0 = options[:text0]
            @text1 = options[:text1]
            @text2 = options[:text2]
            @text3 = options[:text3]
            @background_image = options[:background_image]
        end

        def render
            @background_image0 = @subject_image1 = @subject_image2 = @background_image

            images = {
                background_image: [YCA_WIDTH, YCA_HEIGHT],
                background_image0: [YCA_WIDTH, YCA_HEIGHT],
                subject_image1: [1725, YCA_DESKTOP_HEIGHT],
                subject_image2: [1725, YCA_DESKTOP_HEIGHT]
            }

            each_content(%w(text0 text1 text2 text3), images)
        ensure
            FileUtils.rm_rf @tmpl_dir
            @tmpl_dir = nil
        end
    end
end
