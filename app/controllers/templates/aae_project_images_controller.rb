class Templates::AaeProjectImagesController < ApplicationController
	before_action :set_project_image, only: [:destroy]

	def new
    @aae_project = Templates::AaeProject.find(params[:aae_project_id])
  end

  def destroy
		@aae_project_image.destroy!
  end

	protected
		def set_project_image
			@aae_project_image = Templates::AaeProjectImage.find(params[:id])
		end
end
