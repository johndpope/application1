class Admin::Sandbox::YoutubeChannelImageController < Admin::BaseController
  include GenericCrudOperations

  def initialize
    super
    init_settings({
      clazz: ::Sandbox::YoutubeChannelImage,
      large_form: true,
      view_folder: "admin/sandbox/youtube_channel_image",
      item_params: [:id, :sandbox_client_id, :file, :image_type],
      index_table_header: "Youtube channel image",
      index_page_header: "Youtube channel images"
    })
  end

  def create
    @image = Sandbox::YoutubeChannelImage.new
    @image.sandbox_client_id = params[:sandbox_youtube_channel_image][:sandbox_client_id]
    @image.image_type = params[:sandbox_youtube_channel_image][:image_type]
    @image.file = params[:sandbox_youtube_channel_image][:file].first

    respond_to do |format|
      if @image.save
        format.json { render json: {files: [@image.to_jq_upload]}, status: :created, location: admin_sandbox_youtube_channel_image_path(@image) }
      else
        format.json { render json: @image.errors, status: :unprocessable_entity }
      end
    end
  end

end
