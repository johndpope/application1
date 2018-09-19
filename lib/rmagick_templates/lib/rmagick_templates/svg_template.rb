module RmagickTemplates
    class SvgTemplate
        # Google Plus
        GP_WIDTH = 1600
        GP_HEIGHT = 900
        # Thumbnail
        T_WIDTH = 1280
        T_HEIGHT = 720
        # YouTube channel art
        YCA_WIDTH = 2560
        YCA_HEIGHT = 1440
        YCA_DESKTOP_HEIGHT = 423

        def each_content (text, image)
            require 'open-uri'

            @tmpl_dir = File.join('/tmp', SecureRandom.uuid)
            FileUtils.cp_r "#{tmpl_root_dir}", @tmpl_dir, :verbose => true

            content = {}
            text.each { |e| content[e] = { value: eval("@#{e}") } unless eval("@#{e}").blank? }

            image.each do |i|
                img = i[0].to_s
                img_path = eval("@#{img}")

                unless img_path.blank?
                    filename = File.basename img_path

                    open(File.join(@tmpl_dir, filename), 'wb') do |file|
                        open(img_path) do |uri|
                            file.write(uri.read)
                        end
                    end

                    content[img] = {
                        value: filename,
                        attr: 'xlink:href'
                    }

                    image_scale_crop(content, img, i[1][0], i[1][1]) unless i[1] == false
                end
            end

            update_svg(tmpl_path, content: content)

            do_render
        end

        def image_scale_crop (c, i, w, h)
            orientation = ('horizontal' if w > h) || ('vertical' if w < h) || ('square' if w == h)

            unless c[i].blank?
                # include Magick

                # Source image
                image_path = File.join(@tmpl_dir, c[i][:value])

                # New image
                new_image_name = Random.rand(1000).to_s + SecureRandom.urlsafe_base64.to_s + '.jpg'
                new_image_path = File.join(@tmpl_dir, new_image_name)

                img = Magick::Image.ping(image_path).first

                scale_factor = img.columns >= img.rows ? "x#{h}" : "#{w}x"

                %x(convert #{image_path} -scale #{scale_factor} #{new_image_path};)

                if orientation == 'horizontal'
                    %x(convert #{image_path} -scale #{w}x #{new_image_path};) if ((Magick::Image.ping(new_image_path).first).columns < w)
                elsif orientation == 'vertical'
                    %x(convert #{image_path} -scale x#{h} #{new_image_path};) if ((Magick::Image.ping(new_image_path).first).rows < h)
                end

                %x(convert #{new_image_path} -gravity center -crop #{w}x#{h}+0+0 #{new_image_path};)

                c[i][:value] = new_image_name
            end
        end

        def tmpl_root_dir
            File.join(File.dirname(__FILE__), 'svg_templates', self.class.name.split('::').last.underscore)
        end

        def update_svg (svg_path, options = {})
            svg = Nokogiri::XML(File.open(svg_path))
            unless options[:content].blank? && options[:content].to_a.empty?
                options[:content].each do |key,value|
                    unless value[:value].blank?
                        node = svg.at_css("[id=#{key.to_s}]")
                        if (!value[:attr].blank?)
                            node[value[:attr]] = value[:value]
                        else
                            node.inner_html = value[:value]
                        end
                    end
                end
            end

            svg.css('image').each do |el|
                el['xlink:href'] = "file://#{File.join(@tmpl_dir, File.basename(el['xlink:href']))}"
            end
            File.open(svg_path, 'w') { |f| f.print(svg.to_xml) }
            nil
        end

        def tmpl_path
            File.join(@tmpl_dir, 'tmpl.svg')
        end

        def tmpl_result_path
            File.join(@tmpl_dir, 'result.jpg')
        end

        private
            def do_render
                %x(rsvg-convert #{tmpl_path} -o #{tmpl_result_path})
                # Remove all metadata from output image
                %x(exiv2 rm #{tmpl_result_path})
                Magick::Image.read(tmpl_result_path).first
            end
    end
end
