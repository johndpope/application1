module ImagemagickScripts
    GAMMA = 0.2
    SCRIPT_DIR = File.dirname(__FILE__)

    def self.squareup params = {}
        script_dir = File.dirname(__FILE__)
        script_file = 'squareup.sh'
        cmd = %Q[cd '#{script_dir}' && ./#{script_file} -m crop -s #{params[:width]}x#{params[:height]} #{params[:input]} #{params[:output]}]
        cmd
    end

    #ImagemagickScripts::aspect_crop_cmd '/tmp/input.jpg', '/tmp/output.jpg', '200x100', 'center', 80
    def self.aspect_crop_cmd(input_file, output_file, size, gravity = 'center', quality = nil)
      height = size.split('x')[1]
      width = size.split('x')[0]
      quality_str = !quality.blank? ? "-quality #{quality}" : ''
      cmd1 = %Q(convert '#{input_file}' -auto-orient -resize '#{width}x#{height}^' -gravity '#{gravity}' -crop '#{width}x#{height}+0+0' +repage '#{output_file}')
      cmd2 = %Q(convert '#{output_file}' -auto-orient -resize '#{width}!x#{height}!' -gravity 'center' #{quality_str} '#{output_file}')
      "#{cmd1} && #{cmd2}"
    end

    def self.aspect_crop(input_file, size, gravity = 'c')
      output_image = generate_tmp_file_name(input_file)
      run_cmd(aspect_crop_cmd(input_file, output_image, size, gravity), output_image)
    end

    #ImagemagickScripts/smart_crop('1024x768', '/tmp/test.jpg')
    def self.smart_crop(size, input_image)
      output_image = generate_tmp_file_name(input_image)
      run_cmd("php #{File.join(SCRIPT_DIR, 'smartcropper.php')} size='#{size}' input_image='#{input_image}' output_image='#{output_image}'", output_image)
    end

    def self.slycrop_entropy(size, input_image)
      output_image = generate_tmp_file_name(input_image)
      run_cmd("php '#{File.join(SCRIPT_DIR, "slycrop", "slycrop_entropy.php")}' size='#{size}' input_image='#{input_image}' output_image='#{output_image}'", output_image)
    end

    def self.resize(input_file, size)
      output_image = generate_tmp_file_name(input_file)
      run_cmd("convert '#{input_file}' -auto-orient -resize #{size} #{output_image}", output_image)
    end

    def self.aspect_ratio(width, height)
      float_ar = width.to_f/height.to_f
      n = 1
      limit = 10000
      while (n < limit) do
        m = (float_ar * n + 0.01).to_i # Mathematical rounding
        return "#{m}:#{n}" if ((float_ar - m.to_f/n.to_f).abs < 0.01)
        n += 1
      end
      return "1:1"
    end

    def self.run_cmd(cmd, output_file)
      begin
        %x(#{cmd})
        return Magick::Image.read(output_file).first
      ensure
        FileUtils.rm_f output_file
      end
    end

    def self.generate_tmp_file_name(input_file)
      base_path = File.join('/tmp', 'broadcaster', 'images', 'imagemagick_scripts')
      FileUtils.mkdir_p base_path
      ext = File.extname input_file
      File.join(base_path, "#{SecureRandom.uuid}#{ext}")
    end
end
