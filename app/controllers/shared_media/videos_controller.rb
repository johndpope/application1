class SharedMedia::VideosController < ActionController::Base
  include DataPage
  layout 'shared_media'
  protect_from_forgery
  before_filter :authenticate_user!, except: [:login]
  before_filter :build_data_page

  def index
    options = params.merge({
      q: params[:q],
      user_id: current_user.id,
      page: params[:page],
      limit: params[:limit],
      :ransack => {
        :client_id_eq => params[:client_id_eq],
        :notes_cont => params[:notes_cont],
        :file_file_name_cont => params[:file_file_name_cont],
        :file_content_type_cont => params[:file_content_type_cont],
        :tags_name_cont => params[:tags_name_cont],
        :country_eq => params[:country],
        :region1_eq => params[:region1],
        :region2_eq => params[:region2],
        :city_eq => params[:city]
        }
      }
    )
    search = "Social::Video".constantize.list(options)
    @total_count = search.count

    @videos = Kaminari.paginate_array(
      search[:items],
      total_count: search[:total]
    ).page(params[:page]).per(params[:limit])
  end

  def edit
    @video = Social::Video.find(params[:id])
    respond_to do |format|
      format.js
    end
  end

  def update
    @video = Social::Video.find(params[:id])
    @video.update_attributes(video_params)

    respond_to do |format|
      format.js
    end
  end

  def destroy
    @video = Social::Video.find(params[:id])
    @video.file.destroy
    @video.destroy!
  end

  private
    def video_params
      params.require(:social_video).permit(:title, :notes, :client_id, :tag_list, :country, :region1, :region2, :city )
    end

end
