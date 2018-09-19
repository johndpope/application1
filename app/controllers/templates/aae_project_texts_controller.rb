class Templates::AaeProjectTextsController < ApplicationController
	include Templates::AaeProjectTextConcern
	
	before_action :set_project_text, only: [:destroy]
	before_action :set_aae_project_text_types, only: [:new]

	def new
    @aae_project = Templates::AaeProject.find(params[:aae_project_id])
  end

  def destroy
		@aae_project_text.destroy!
  end

	protected
		def set_project_text
			@aae_project_text = Templates::AaeProjectText.find(params[:id])
		end
end
