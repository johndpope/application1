class SharedMedia::AudiosController < ActionController::Base
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
        :tags_name_cont => params[:tags_name_cont]
        }
      }
    )
    search = "Social::Audio".constantize.list(options)
    @total_count = search.count

    @audios = Kaminari.paginate_array(
      search[:items],
      total_count: search[:total]
    ).page(params[:page]).per(params[:limit])
  end

  def edit
    @audio = Social::Audio.find(params[:id])
    respond_to do |format|
      format.js
    end
  end

  def update
    @audio = Social::Audio.find(params[:id])
    @audio.update_attributes(audio_params)

    respond_to do |format|
      format.js
    end
  end


  def destroy
    @audio = Social::Audio.find(params[:id])
    @audio.file.destroy
    @audio.destroy!
  end

  protected
    def build_data_page
      @data_page = "#{params[:controller].gsub('/', '_')}_#{params[:action]}"
      @body_class = "#{params[:controller].gsub('/', '_')} #{params[:action]}"
    end

  private
    def audio_params
      params.require(:social_audio).permit(:title, :client_id, :tag_list, :notes)
    end

end
