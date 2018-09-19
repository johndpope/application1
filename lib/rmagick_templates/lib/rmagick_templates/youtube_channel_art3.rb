module RmagickTemplates
    class YoutubeChannelArt3 < SvgTemplate
        # RmagickTemplates::YoutubeChannelArt3.new(text: 'Trane comercial video', subject_image1: '/home/master/img1.jpg', subject_image2: '/home/master/img3.jpg', background_image: '/home/master/img4.jpg').render.write('/home/master/yca3.jpg')

        def initialize(options = {})
            @text = options[:text]
            @background_image = options[:background_image]
            @subject_image1 = options[:subject_image1]
            @subject_image2 = options[:subject_image2]
        end

        def render
            images = {
                background_image: [YCA_WIDTH, YCA_HEIGHT],
                subject_image1: [278, 278],
                subject_image2: [278, 278]
            }

            each_content(%w(text), images)
        ensure
            FileUtils.rm_rf @tmpl_dir
            @tmpl_dir = nil
        end
    end
end
