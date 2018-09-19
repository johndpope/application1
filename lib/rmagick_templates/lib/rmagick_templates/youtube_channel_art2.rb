module RmagickTemplates
    class YoutubeChannelArt2 < SvgTemplate
        # RmagickTemplates::YoutubeChannelArt2.new(text1: 'Hillary', text2: 'Presidential', subject_image1: '/home/master/img3.jpg', subject_image2: '/home/master/img4.jpg', subject_image3: '/home/master/img1.jpg', background_image: '/home/master/img2.jpg').render.write('/home/master/yca2.jpg')

        def initialize(options = {})
            @text1 = options[:text1]
            @text2 = options[:text2]
            @subject_image1 = options[:subject_image1]
            @subject_image2 = options[:subject_image2]
            @subject_image3 = options[:subject_image3]
            @background_image = options[:background_image]
        end

        def render
            @background_image0 = @background_image1 = @background_image

            images = {
                background_image: [YCA_WIDTH, YCA_HEIGHT],
                background_image0: [YCA_WIDTH, YCA_HEIGHT],
                background_image1: [YCA_WIDTH, YCA_DESKTOP_HEIGHT],
                subject_image1: [378, YCA_DESKTOP_HEIGHT],
                subject_image2: [378, YCA_DESKTOP_HEIGHT],
                subject_image3: [378, YCA_DESKTOP_HEIGHT]
            }

            each_content(%w(text1 text2), images)
        ensure
            FileUtils.rm_rf @tmpl_dir
            @tmpl_dir = nil
        end
    end
end
