module RmagickTemplates
    class YoutubeChannelArt6 < SvgTemplate
        # RmagickTemplates::YoutubeChannelArt6.new(text0: 'FLORIDA', text1: 'Hillary&apos;s Campaign', text2: 'Kick-off Trip', subject_image1: '/home/master/img3.jpg', subject_image2: '/home/master/img4.jpg').render.write('/home/master/yca6.jpg')

        def initialize(options = {})
            @text0 = options[:text0]
            @text1 = options[:text1]
            @text2 = options[:text2]
            @subject_image1 = options[:subject_image1]
            @subject_image2 = options[:subject_image2]
        end

        def render
            images = {
                subject_image1: [2120, YCA_DESKTOP_HEIGHT],
                subject_image2: [776, YCA_DESKTOP_HEIGHT]
            }

            each_content(%w(text0 text1 text2), images)
        ensure
            FileUtils.rm_rf @tmpl_dir
            @tmpl_dir = nil
        end
    end
end
