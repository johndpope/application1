class Artifacts::BlendedImagesController < Artifacts::BaseController
  include GenericCrudOperations
  before_action :set_dynamic_image, only: %w(show_modal_image_image show_modal_image_text)

  def initialize
    super
    init_settings({
      clazz: ::Artifacts::DynamicImage,
      view_folder: "artifacts/blended_images",
      large_form: true,
      item_params: [
        :id,
        :title
      ],
      breadcrumbs: {name: :artifacts_blended_images},
      show_add_button: false,
      show_edit_button: false,
			index_table_header: 'dynamic images',
			index_page_header: 'Dynamic images',
      index_title: 'Dynamic Images',
      javascripts: %w(jquery.remotipart jquery-live-preview)
    })
  end

  def show_modal_image_text
  end

  def show_modal_image_image
    img = []
    @item.images.each do |item|
        img.push(Artifacts::Image.find(item.artifacts_image_id)) if !item.artifacts_image_id.blank?
    end
    @dynamic_image_images = img
  end

  private
    def set_dynamic_image
      @item = Artifacts::DynamicImage.find params[:blended_image_id]
    end

end
