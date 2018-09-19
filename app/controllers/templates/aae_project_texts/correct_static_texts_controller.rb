class Templates::AaeProjectTexts::CorrectStaticTextsController < ApplicationController
	LIMIT = 25
  def index
		@search = Templates::AaeProjectText.search(params[:q])
		@search.sorts = ''
		total_count = @search.result.where(is_static: true).pluck(:aae_project_id).count

		aae_template_ids = @search.result.where(is_static: true).
			order(aae_project_id: :desc).
			group(:aae_project_id).
			page(params[:page]).per(LIMIT).
			pluck(:aae_project_id)

		@items = @search.result.where(is_static: true).order(id: :desc).group_by(&:aae_project_id)
		@limit = LIMIT
		@test_outputs = Templates::DynamicAaeProject.
			with_target(:test).
			where(aae_project_id: aae_template_ids).
			where.not(rendered_video_file_name: nil).map{|dp|{dp.aae_project_id => dp.rendered_video.url}}.reduce({}, :merge)

		@aae_templates = Kaminari.paginate_array(
			Templates::AaeProject.where(id: aae_template_ids),
			total_count: total_count
		).page(params[:page]).per(LIMIT)
  end

  def update
		@static_text = Templates::AaeProjectText.find(params[:aae_project_text_id])
		@static_text.update params.require(:templates_aae_project_text).permit(:corrected_value)
  end
end
