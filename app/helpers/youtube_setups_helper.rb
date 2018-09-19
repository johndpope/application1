module YoutubeSetupsHelper
	# YouTube video annotation/card template or YVT
	def video_template_form
		symStatus = :ok
		json = JSON.parse(params[:json])
		@yvt = "YoutubeVideo#{params[:type].capitalize}Template".constantize.new(json)
		symStatus = :unprocessable_entity if json["#{params[:type]}_type".to_sym].present? && !@yvt.valid?

		respond_to do |format|
			format.html { render partial: "youtube_setups/#{params[:type]}/form", status: symStatus }
		end
	end

	def video_template_list
		render partial: "youtube_setups/#{params[:type]}/list", locals: { item: JSON.parse(params[:array_of_jsons]) }
	end
end
