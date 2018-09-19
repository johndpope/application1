class Templates::ImageTemplatesController < ApplicationController
  include GenericCrudOperations

  before_action :set_template_images, only: %w(preview_sample texts)

  def initialize
    super
    init_settings({
      clazz: ::Templates::ImageTemplate,
      view_folder: "templates/image_templates",
      large_form: true,
      item_params: [
        :id,
        :name,
        :type,
				:category,
        :client_id,
        :product_id,
        :is_active,
        :sample,
        :svg,
        texts_attributes: [:id, :name, :image_template_id],
        images_attributes: [:id, :name, :image_template_id, :width, :height]
      ],
      breadcrumbs: {name: :image_templates},
      index_search_sorts: 'name',
			index_table_header: 'Image templates',
			index_page_header: 'Image templates',
      index_title: 'Templates',
      javascripts: %w(jquery.remotipart)
    })
  end


  def index
    @items.each_with_index{|e,index|@items[index] = @items[index].becomes Templates::ImageTemplate}
    super
  end

  def new
    super
    @item = @item.becomes Templates::ImageTemplate
  end

  def create
    @item = @clazz.new(item_params)
		if @item.save
      @item = @item.becomes Templates::ImageTemplate
      create_item @item
		else
    	form_dialog @item
		end
  end

  def create_item(item)
    super
  end

  def form_dialog(item)
    super
  end

  def edit
    @item = @item.becomes Templates::ImageTemplate
    super
  end

  def destroy
    @item = @item.becomes Templates::ImageTemplate
    super
  end

  def update
    @item = @item.becomes Templates::ImageTemplate
    super
  end

  def preview_sample
    respond_to{|format| format.js}
  end

  def texts
    respond_to{|format| format.js}
  end

  def fields
    respond_to{|format| format.js}
  end

  private
    def set_template_images
      @item = Templates::ImageTemplate.find params[:image_template_id]
    end
end
