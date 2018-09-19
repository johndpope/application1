class Artifacts::ImageBlenderController < Artifacts::BaseController
  before_action :init_templates, only: %w(index image_template_settings)
  LIMIT = 9

  def index
  end

  def blend
    tmp_file_path = "/tmp/artifacts-tmp-image-#{SecureRandom.uuid}.png"

    begin
      sanitized_params = params.require(:image_blender)
      id = sanitized_params[:image_template_id]

      Templates::ImageTemplate.find(id).render(sanitized_params[:images],sanitized_params[:texts]).write(tmp_file_path)
      @tmp_image = Artifacts::TmpImage.first_or_initialize do |i|
        i.admin_user_id = current_admin_user.id
      end

      f = File.open(tmp_file_path)
      @tmp_image.file = f
      @tmp_image.save!
      f.close
    rescue Exception => e
      puts e.message
      puts e.backtrace
    ensure
      FileUtils.rm_rf tmp_file_path
    end
  end

  def import_image
      sanitized_params = params.require(:image_blender)

      dynamic_image = Artifacts::DynamicImage.create_from_params(sanitized_params)
      tmp_image = Artifacts::TmpImage.find_by_admin_user_id(current_admin_user.id)

      f = File.open(tmp_image.file.path)
      dynamic_image.file = f
      dynamic_image.save!
      f.close
  end

  def save_image

    img = Artifacts::DynamicImage.last
    source_id = img.id
    type = img.image_template.type

    country = Geobase::Country.find(1)
    region1 = params[:region1].present? ? Geobase::Region.find(params[:region1]) : nil
    region2 = params[:region2].present? ? Geobase::Region.find(params[:region2]) : nil
    city = params[:city].present? ? Geobase::Locality.find(params[:city]) : nil
    client_id = params[:client_id].present? ? params[:client_id] : nil
    title = params[:title].present? ? params[:title] : nil

    @img = Artifacts::Image.new(
      title: title,
      country: country.try(:name),
      region1: region1.try(:name),
      region2: region2.try(:name),
      city: city.try(:name),

      dynamic_image_id: img.id,
      client_id: client_id,
      is_local: true,
      admin_user_id: current_admin_user.id,
      reusable: true,

      tag_list: if (tags = params[:tag_list])
                  tags.split(',').map(&:strip).map{|e|e.mb_chars.downcase.to_s}.uniq.reject(&:blank?)
                end
    )
    f = File.open(img.file.path)
    @img.file = f
    @img.save!
    f.close
  end

  def image_template_settings
    @template = Templates::ImageTemplate.find(params[:image_template_id])
  end

  def templates_by_type
    type = params[:type]
    @templates_by_type = Templates::ImageTemplate.where(:type => "#{type}").where(:is_active => true).order(:name)
  end

  def select_image
    @image_field = params[:image_field]
  end

  def select_logo
    @client = Client.find(params[:image_blender][:id_client])
  end

  def image_info
    file_path = Artifacts::Image.find(params[:image_id]).file.path
    @dimensions = Paperclip::Geometry.from_file(file_path)
  end

  def search
    limit = params[:limit].blank? ? LIMIT : params[:limit]
    @images = Artifacts::Image
      .where(:dynamic_image_id => nil)
      .where.not(:file_file_name => nil)
      .ransack(params[:q])
      .result(distinct: true).page(params[:page]).per(limit)
  end

  private
    def init_templates
      @templates = Templates::ImageTemplate.order(:name)

      typesArr = []
      @templates.each do |item|
        unless item.type == nil
          typesArr.push(item.type)
        end
      end
      typesArr = typesArr.uniq

      tp = []
      typesArr.each do |type|
        tp.push(type.split("::")[1])
      end
      @types = tp

    end

end
