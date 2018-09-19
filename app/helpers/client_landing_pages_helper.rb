module ClientLandingPagesHelper
	def preview_img (type = :thumb)
		id = @client_landing_page.client_landing_page_template_id
		(id.present? ? ClientLandingPageTemplate.find_by_id(id) : ClientLandingPageTemplate.order(name: :asc).first).preview.url(type)
	end

	def get_tamplate
		template = ClientLandingPageTemplate.find_by_id(params[:id])

		paths_to_images = if !template.preview.blank?
			{
				thumb: template.preview.url(:thumb),
				original: template.preview.url(:original)
			}
		else
			{}
		end

		render json: paths_to_images.to_json
	end
end
