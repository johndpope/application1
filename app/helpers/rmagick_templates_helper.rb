module RmagickTemplatesHelper
    TMPLS_ARGS = {
        'google_plus_art1' => { images: [:background_image], texts: [:text1, :text2, :text3, :text4] },
        'google_plus_art2' => { images: [:background_image, :subject_image1, :subject_image2, :subject_image3], texts: [:text] },
        'google_plus_art4' => { images: [:background_image], texts: [:text1, :text2, :text3, :text4] },
        'google_plus_art5' => { images: [:background_image], texts: [:text0, :text1, :text2, :text3] },
        'google_plus_art6' => { images: [:background_image], texts: [:text0, :text1, :text2] },
        'google_plus_art7' => { images: [:background_image, :subject_image], texts: [:text1, :text2] },
        'google_plus_art8' => { images: [:subject_image], texts: [:text1, :text2] },
        'google_plus_art9' => { images: [:background_image, :subject_image], texts: [:text0, :text1, :text2, :text3] },
        'google_plus_art10' => { images: [:background_image, :subject_image], texts: [:text1, :text2, :text3, :text4] },
        'thumbnail1' => { images: [:background_image, :subject_image], texts: [:text0, :text1, :text2, :text3] },
        'thumbnail2' => { images: [:background_image, :subject_image], texts: [:text0, :text1, :text2] },
        'thumbnail3' => { images: [:background_image, :subject_image1, :subject_image2, :subject_image3], texts: [:text0, :text1] },
        'thumbnail4' => { images: [:background_image, :subject_image1, :subject_image2, :subject_image3, :subject_image4], texts: [:text0, :text1] },
        'thumbnail5' => { images: [:subject_image1, :subject_image2, :subject_image3, :logo], texts: [:text0, :text1] },
        'thumbnail6' => { images: [:subject_image1, :subject_image2, :subject_image3, :subject_image4], texts: [:text0, :text1, :text2] },
        'thumbnail7' => { images: [:background_image, :subject_image], texts: [:text0, :text1, :text2] },
        'thumbnail8' => { images: [:background_image, :subject_image], texts: [:text0, :text1, :text2] },
        'thumbnail9' => { images: [:subject_image, :logo], texts: [:text0, :text1] },
        'thumbnail10' => { images: [:background_image, :subject_image1, :subject_image2], texts: [:text0, :text1, :text2, :text3] },
        'thumbnail11' => { images: [:background_image1, :background_image2, :subject_image], texts: [:text0, :text1, :text2] },
        'youtube_channel_art1' => { images: [:background_image], texts: [:text1, :text2] },
        'youtube_channel_art2' => { images: [:background_image, :subject_image1, :subject_image2, :subject_image3], texts: [:text1, :text2] },
        'youtube_channel_art3' => { images: [:background_image, :subject_image1, :subject_image2], texts: [:text] },
        'youtube_channel_art4' => { images: [:background_image], texts: [:text1, :text2] },
        'youtube_channel_art5' => { images: [:background_image], texts: [:text0, :text1, :text2, :text3] },
        'youtube_channel_art6' => { images: [:subject_image1, :subject_image2], texts: [:text0, :text1, :text2] },
        'youtube_channel_art7' => { images: [:background_image, :subject_image], texts: [:text1, :text2] },
        'youtube_channel_art8' => { images: [:background_image], texts: [:text1, :text2] },
        'youtube_channel_art9' => { images: [:background_image, :subject_image], texts: [:text0, :text1] },
        'youtube_channel_art10' => { images: [:background_image, :subject_image], texts: [:text1, :text2] }
    }

    def make_still_image (template_name, template_args, size = 10)
        tmpl_dir = File.join('/tmp', SecureRandom.uuid)
        FileUtils.mkdir_p tmpl_dir

        begin
            options = {}

            underscored_template_name = template_name.underscore
            template_args = TMPLS_ARGS[underscored_template_name]
            template_args[:texts].each{ |txt| options[txt] = 'Lorem Ipsum' }

            output_file = "/tmp/#{underscored_template_name}.mp4"

            1.upto size.to_i do |i|
                puts "Generating template %03d" % i

                template_args[:images].each do |img|
                    image = Artifacts::Image
                        .where('file_file_name IS NOT NULL')
                        .where('(width::float / height::float) between 1.33 and 1.77 OR width >= 1500')
                        .first(order: 'random()')
                    options[img] = image.file.path
                end

                tmpl = eval("RmagickTemplates::#{template_name}.new(options)")
                tmpl.render.write(File.join(tmpl_dir, "#{template_name}_%03d.jpg" % i))
            end

            %x(cd #{tmpl_dir} && ffmpeg -framerate 0.5 -i #{template_name}_%03d.jpg #{output_file})
        ensure
            FileUtils.rm_rf tmpl_dir
        end
    end

    def make_random_image_set(image_tags, prefix, extention = 'jpg', dimensions, count)
      tmpl_dir = File.join('/tmp', SecureRandom.uuid)
      FileUtils.mkdir_p tmpl_dir

      1.upto count.to_i  do |i|
        image = Artifacts::Image.downloaded.with_tags(image_tags).with_aspect_ratio(1.33, 1600).order('random()').first
        img_path = File.join(tmpl_dir, "#{prefix}_#{i}.#{extention}")
        open(img_path, 'wb') do |file|
            open(image.file.path) do |uri|
                file.write(uri.read)
            end
        end

        %x(convert #{img_path} -gravity center -crop #{dimensions}+0+0 #{img_path};)
      end

      puts "The images are stored in #{tmpl_dir}"
    end
end
