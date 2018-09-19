class Artifacts::IconController < Artifacts::BaseController
  LIMIT = 9
  ICON_TML_DIR = File.join("/tmp", "broadcaster", "icons")
  COLLECT_DIR = Rails.root.join("public/system/artifacts/tmp_images/collect")
  skip_before_filter :verify_authenticity_token, :only => [:save, :delete]

  def index
  end

  def settings
    tmpl_dir = File.join(ICON_TML_DIR, SecureRandom.uuid)
    FileUtils.mkdir_p tmpl_dir

    @xml_path = File.join(tmpl_dir, "icon_template.svg")
    @result_path = File.join(tmpl_dir, "icon_result.png")
    icon_path = params[:icon][:path]
    FileUtils.cp_r icon_path, @xml_path
    xml = Nokogiri::XML(File.open(@xml_path))

    content = xml.at_css("style").children.text.strip.split(/\n/).each do |item|
      color = item.match(/\.\w+/).to_s.delete('.')
      value = "##{params['icon_colors'][color]}"
      item.gsub!(/#.{6}/, value)
    end

    xml.at_css("style").inner_html = "\n\t<![CDATA[\n\t\t#{content.join("\n\t\t")}\n\t]]>\n"

    if File.exists?(@xml_path)
      File.open(@xml_path, 'w'){|f| f.print(xml.to_xml)}
      %x(rsvg-convert #{@xml_path} -o #{@result_path})
      %x(exiv2 rm #{@result_path})
      Magick::Image.read(@result_path).first
    else
      puts "Image path is nil"
    end

    begin
      @tmp_image = Artifacts::TmpImage.first_or_initialize do |i|
        i.admin_user_id = current_admin_user.id
      end
      f = File.open(@result_path)
      @tmp_image.file = f
      @tmp_image.save!
      f.close

      FileUtils.mkdir_p COLLECT_DIR
      @collect_path = File.join(COLLECT_DIR,"version#{SecureRandom.uuid}.png")
      FileUtils.cp_r @result_path, @collect_path
      @images = Dir[File.join(COLLECT_DIR, "*")]

    rescue Exception => e
      puts e.message
      puts e.backtrace
    ensure
      FileUtils.rm_rf tmpl_dir
    end

  end

  def browse_icon
  end

  def delete
    if params[:image_path] == ""
      FileUtils.rm_rf COLLECT_DIR
    else
      FileUtils.rm_rf params[:image_path]
    end
    respond_to do |format|
      format.json{ head :no_content }
    end
  end

  def get_icon_file
    xml = Nokogiri::XML(File.open(params[:image_path]))
    @options = {}
    xml.at_css("style").children.text.strip.split(/\n/).each{|item|
      key = item.match(/\.\w+/).to_s.delete('.')
      val = item.match(/\#\w+/).to_s
      @options[key] = val
    }
    FileUtils.rm_rf COLLECT_DIR
  end

  def save
    country = params[:data][:country].present? ? Geobase::Country.find(params[:data][:country]) : nil
    region1 = params[:data][:region1].present? ? Geobase::Region.find(params[:data][:region1]) : nil
    region2 = params[:data][:region2].present? ? Geobase::Region.find(params[:data][:region2]) : nil
    city = params[:data][:city].present? ? Geobase::Locality.find(params[:data][:city]) : nil
    title = params[:data][:title].present? ? params[:data][:title] : nil
    notes = params[:data][:notes].present? ? params[:data][:notes] : nil
    client_id = params[:data][:client_id].present? ? params[:data][:client_id] : nil
    industry_id = params[:data][:industry_id].present? ? params[:data][:industry_id] : nil
    icon_temp_file_path = params[:data][:icon_temp_file_path].present? ? params[:data][:icon_temp_file_path] : nil
    @image = Artifacts::IconImage.new(
      country: country.try(:name),
      region1: region1.try(:name),
      region2: region2.try(:name),
      city: city.try(:name),
      admin_user_id: current_admin_user.id,
      tag_list: if (tags = params[:data][:tag_list])
                  tags.split(',').map(&:strip).map{|e|e.mb_chars.downcase.to_s}.uniq.reject(&:blank?) unless tags.nil?
                end,
      title: title,
      is_local: true,
      notes: notes,
      is_special: true,
      client_id: client_id,
      industry_id: industry_id
    )
    f = File.open(icon_temp_file_path)
    @image.file = f
    @image.save!
    f.close
    FileUtils.rm_rf icon_temp_file_path
  end

  def search
    limit = params[:limit].blank? ? LIMIT : params[:limit]
    @icons = Artifacts::Image.where(:file_content_type => "image/svg+xml")
      .ransack(params[:q])
      .result(distinct: true).page(params[:page]).per(limit)
  end

end
