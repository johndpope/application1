class BlendingPatternsController < ApplicationController
	include GenericCrudOperations

	def initialize
    super
    init_settings({
			clazz: BlendingPattern,
		  view_folder: "blending_patterns",
			item_params: [:id, :client_id, :product_id, :name, :source_video_id, :value],
			index_table_header: I18n.t('blending_pattern.blending_patterns_list'),
			index_page_header: I18n.t('blending_pattern.blending_patterns'),
			large_form: false,
			breadcrumbs: {name: :blending_patterns}
		})
	end

	def add_blending_pattern_item

	end

	%w(source_videos products).each do |m|
		define_method m do
			search = m.singularize.camelize.constantize.search(params).result

			respond_to do | format |
				format.json do
					render json: {
						total: search.count,
						items: search.page(params[:page]).per(params[:per_page])
					}
				end
			end
		end
	end
end
