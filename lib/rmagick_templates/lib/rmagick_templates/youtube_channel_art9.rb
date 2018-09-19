module RmagickTemplates
    class YoutubeChannelArt9 < SvgTemplate
        # RmagickTemplates::YoutubeChannelArt9.new(text0: 'florida', text1: 'Kliemann Bros', subject_image: '/home/master/img4.jpg', background_image: '/home/master/img0.jpg').render.write('/home/master/yca9.jpg')

        def initialize(options = {})
            @text0 = options[:text0]
            @text1 = options[:text1]
            @background_image = options[:background_image]
            @subject_image = options[:subject_image]
        end

        def render
            @background_image0 = @background_image1 = @background_image

            images = {
                background_image: [YCA_WIDTH, YCA_HEIGHT],
                background_image0: [YCA_WIDTH, YCA_HEIGHT],
                background_image1: [YCA_WIDTH, YCA_DESKTOP_HEIGHT],
                subject_image: [1134, YCA_DESKTOP_HEIGHT]
            }

            each_content(%w(text0 text1 text2), images)
        ensure
            FileUtils.rm_rf @tmpl_dir
            @tmpl_dir = nil
        end
    end
end
