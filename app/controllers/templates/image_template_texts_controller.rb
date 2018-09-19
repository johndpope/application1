class Templates::ImageTemplateTextsController < ApplicationController
  before_action :set_image_template_text, only: [:destroy]

  def new
    @image_template = Templates::ImageTemplate.new
  end

  def destroy
	  @image_template_text.destroy!
  end

	protected
		def set_image_template_text
			@image_template_text = Templates::ImageTemplateText.find(params[:id])
		end

  private
    def user_params
      params.require(Templates::ImageTemplateImage.to_sym).permit(:image_template_id, :name, :width, :height);
    end

end
