class SharedMedia::ImagesController < ActionController::Base
  include DataPage
  layout 'shared_media'

  IMAGES_LIMIT = 100
  protect_from_forgery
  before_filter :authenticate_user!, except: [:login]
  before_filter :build_data_page

  def dashboard
  end

  def index
    search = { total: 0, items: [] }
    params[:limit] = IMAGES_LIMIT unless params[:limit].present?

    @user_id = current_user.id
    options = params.merge({
      q: params[:q],
      user_id: current_user.id,
      page: params[:page],
      limit: params[:limit]
      })
    search = "Social::Image".constantize.list(options)
    @total_count = search[:total]
    @images = Kaminari.paginate_array(
      search[:items],
      total_count: search[:total]
    ).page(params[:page]).per(params[:limit])
  end

  def edit
    @image = Social::Image.find(params[:id])
    respond_to do |format|
      format.js
    end
  end

  def update
    @image = Social::Image.find(params[:id])
    @image.update_attributes(
      title: params[:social_image][:title],
      country: params[:country].blank? ? nil : Geobase::Country.find(params[:country]).id,
      region1: params[:region1].blank? ? nil : Geobase::Region.find(params[:region1]).id,
      region2: params[:region2].blank? ? nil : Geobase::Region.find(params[:region2]).id,
      city: params[:city].blank? ? nil : Geobase::Locality.find(params[:city]).id,
      tag_list: if (tags = params[:social_image][:tag_list])
                  tags.split(',').map(&:strip).map{|e| e.mb_chars.downcase.to_s}.uniq.reject(&:blank?)
                end,
      notes: params[:social_image][:notes]
      )
  end

  def destroy
    @image = Social::Image.find(params[:id])
    image_path = @image.file.path.gsub("original/#{@image.file.original_filename}",'')
    FileUtils.rm_rf image_path
    @image.destroy!
    respond_to do |format|
      format.js
    end
  end

  def local_import
  end

  def group_update

    unless params["images"].blank?
      images = params["images"]
      images.each do |image|
        id = image[0]
        item = image[1]
        unless id.blank?
          Social::Image.find(id).update_attributes(
            :title => item["title"],
            :country => item["country"],
            :region1 => item["region1"],
            :region2 => item["region2"],
            :city => item["city"],
            :notes => item["notes"],
            :tag_list => item["tags"].blank? ? "" : item["tags"].split(',').uniq
          )
        end
      end
    end

    unless params["audios"].blank?
      audios = params["audios"]
      audios.each do |audio|
        id = audio[0]
        item = audio[1]
        unless id.blank?
          Social::Audio.find(id).update_attributes(
            :title => item["title"],
            :notes => item["notes"],
            :tag_list => item["tags"].blank? ? "" : item["tags"].split(',').uniq
          )
        end
      end
    end

    unless params["videos"].blank?
      videos = params["videos"]
      videos.each do |video|
        id = video[0]
        item = video[1]
        unless id.blank?
          Social::Video.find(id).update_attributes(
            :title => item["title"],
            :notes => item["notes"],
            :tag_list => item["tags"].blank? ? "" : item["tags"].split(',').uniq,
            :country => item["country"],
            :region1 => item["region1"],
            :region2 => item["region2"],
            :city => item["city"]
          )
        end
      end
    end

    respond_to do |format|
      format.js
    end
  end

  def upload
    file_type = params[:file].content_type.split('/').first unless params[:file].blank?
    %w(image audio video).each do |item|
      if item == file_type
        @media_item = "Social::#{item.to_s.capitalize}".constantize.new
        @media_item.file = params[:file]
        file_name = @media_item.try(:file_file_name).to_s
        title = File.basename(file_name).gsub(File.extname(file_name), '').to_s.humanize
        @media_item.title = title
        @media_item.notes = params[:notes] unless params[:notes].blank?
        @media_item.tag_list = params[:tags].split(',').map(&:strip).uniq unless params[:tags].blank?
        @media_item.user_id = current_user.id
        @media_item.client_id = params[:client_id]

        %w(country region1 region2 city).each do |p|
          @media_item.send("#{p}=", params["#{item}"][p.to_sym]) unless params["#{item}"][p.to_sym].blank?
        end

        respond_to do |format|
          if @media_item.save
            format.json{render json: {files: [@media_item.to_jq_upload]}, status: :created }
          else
            format.json{render json: @media_item.errors, status: :unprocessable_entity }
          end
        end

      end
    end
  end

  def products_for_client
    @products_for_client = Product.where(:client_id => "#{params[:client_id]}").select('id','name').order(:name)
    @tags_for_client = Client.find("#{params[:client_id]}").tag_list unless params[:client_id].blank?
  end

  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end

  def region1_coverage

    counts = Social::Image.joins(
      <<-SQL
        RIGHT OUTER JOIN geobase_regions
          ON social_images.region1::bigint = geobase_regions.id
            AND geobase_regions.level = 1
      SQL
    ).group('1').pluck("split_part(geobase_regions.code, '<sep/>', 1), count(social_images.*)")

    respond_to do |format|
      format.json { render json: Hash[counts] }
    end
  end

  def region2_coverage
    region1 = Geobase::Region.where('code LIKE ?', "%#{params[:region1]}%").first
    counts = Social::Image.joins(
      %Q[
        RIGHT OUTER JOIN geobase_regions
          ON social_images.region2::bigint = geobase_regions.id
            AND geobase_regions.parent_id = #{region1.id}
            AND social_images.region1 = '#{region1.id}'
      ]
    ).group('1').pluck("'#{region1.code.to_s.split('<sep/>').first.to_s}' || ' ' || geobase_regions.name || ' ' || 'County', count(social_images.*)")
    respond_to do |format|
      format.json { render json: Hash[counts] }
    end
  end

  protected
    def build_data_page
      @data_page = "#{params[:controller].gsub('/', '_')}_#{params[:action]}"
      @body_class = "#{params[:controller].gsub('/', '_')} #{params[:action]}"
    end
end
