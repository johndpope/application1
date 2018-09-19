module RmagickTemplates
    class YoutubeChannelArt7 < SvgTemplate
        # RmagickTemplates::YoutubeChannelArt7.new(text1: 'Top Secret', text2: 'Deer Scents', subject_image: '/home/master/img1.jpg', background_image: '/home/master/img2.jpg').render.write('/home/master/yca7.jpg')

        def initialize(options = {})
            @text1 = options[:text1]
            @text2 = options[:text2]
            @background_image = options[:background_image]
            @subject_image = options[:subject_image]
        end

        def render
            @background_image0 = @background_image1 = @background_image

            images = {
                background_image: [YCA_WIDTH, YCA_HEIGHT],
                background_image0: [YCA_WIDTH, YCA_HEIGHT],
                background_image1: [YCA_WIDTH, YCA_DESKTOP_HEIGHT],
                subject_image: [814, YCA_DESKTOP_HEIGHT]
            }

            each_content(%w(text1 text2), images)
        ensure
            FileUtils.rm_rf @tmpl_dir
            @tmpl_dir = nil
        end
    end
end
