class Templates::ImageTemplateImagesController < ApplicationController
  before_action :set_project_image, only: [:destroy]

  def new
    @image = Templates::ImageTemplateImage.new
  end

  def destroy
    @image_template_image.destroy!
  end

  protected
    def set_project_image
      @image_template_image = Templates::ImageTemplateImage.find(params[:id])
    end
end
