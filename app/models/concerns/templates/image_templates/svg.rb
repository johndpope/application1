require 'open-uri'
module Templates::ImageTemplates::Svg
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

  IMAGE_TML_DIR = File.join("/tmp", "broadcaster", "image_templates")

  def crop (image_path, width = 100, height = 100, image_type)
      orientation = if width > height
        'horizontal'
      elsif width < height
        'vertical'
      elsif width == height
        'square'
      end

      geometry = Magick::Image.ping(image_path).first
      scale_factor = geometry.columns >= geometry.rows ? "#{width}x" : "x#{height}"

      %x(convert "#{image_path}" -scale #{scale_factor} "#{image_path}";)
      if orientation == 'horizontal'
          %x(convert #{image_path} -scale #{width}x#{height}! #{image_path};)
      elsif orientation == 'vertical'
          %x(convert #{image_path} -scale x#{height} #{image_path};) if geometry.rows < height && image_type != 'icon_image'
      end
      %x(convert #{image_path} -gravity center -crop #{width}x#{height}+0+0 #{image_path};)
  end

# example:
# Templates::ImageTemplate.find(375).render(images: {subject_image: '/home/master/11/img1.jpg', icon_image: '/home/master/00/logo1.jpg'}).write('/home/master/00/result.jpg')

  def render( images = {}, texts = {})
    tmpl_dir = File.join(IMAGE_TML_DIR, SecureRandom.uuid)
    FileUtils.mkdir_p tmpl_dir

    xml_path = File.join(tmpl_dir, "template.svg")
    result_path = File.join(tmpl_dir, "result.png")

    begin
      if (self.svg.blank? || !File.exists?(self.svg.path))
        raise "Couldn't access template's SVG file"
      end

      FileUtils.cp_r self.svg.path, xml_path

      content = {images: images, texts: texts }

      self.images.each do |tmpl_image|
        key = tmpl_image.name.to_sym

        if images.has_key? key

          tmp_image_extension = File.extname(images[key])
          tmp_image_filename = "#{SecureRandom.uuid}#{tmp_image_extension}"
          tmp_image_path = File.join(tmpl_dir, tmp_image_filename)

          FileUtils.cp_r images[key], tmp_image_path
          crop tmp_image_path, tmpl_image.width, tmpl_image.height, tmpl_image.name
          content[:images][key] = tmp_image_path

        end
      end

      content[:texts] = {}
      self.texts.each do |tmpl_text|
        key = tmpl_text.name.to_sym
        texts.each do |k,v|
            content[:texts][k.to_sym] = v.to_s
        end
      end

      #update svg content
      #вставить текст в найденный node
      xml = Nokogiri::XML(File.open(xml_path))
      content[:texts].each do |text_name, text_value|
        if node = xml.at_css("[id=#{text_name.to_s}]")
          node.inner_html = text_value
        end
      end

      #прописать путь в href
      content[:images].each do |image_name, image_value|
        if node = xml.at_css("[id=#{image_name.to_s}]")
          node['xlink:href'] = image_value

          #change wight/height attributes
          nm = self.images.find_by name: "#{image_name.to_s}"
          node['width'] = "#{nm.width}"
          node['height'] = "#{nm.height}"
        end

      end

      File.open(xml_path, 'w') { |f| f.print(xml.to_xml) }

      %x(rsvg-convert #{xml_path} -o #{result_path})
      %x(exiv2 rm #{result_path})
      Magick::Image.read(result_path).first


    rescue Exception => e
      puts e.message
      puts e.backtrace
      raise "Failed to render Image Template"
    ensure
      FileUtils.rm_rf tmpl_dir
    end
  end

end
