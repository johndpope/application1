class Templates::DynamicAaeProjectsController < ApplicationController
	include DataPage
	include GenericCrudOperations

	before_action :set_dynamic_aae_project, only: %w(texts images)
	before_action :set_iconed_columns, only: :index

	def initialize
		super
    init_settings({
			clazz: ::Templates::DynamicAaeProject,
		  view_folder: "templates/dynamic_aae_projects",
			large_form: true,
			show_action_bar: false,
			index_table_header: I18n.t('templates.dynamic_aae_projects_list'),
			index_page_header: I18n.t('templates.dynamic_aae_projects'),
			javascripts: %w(fancybox),
			stylesheets: %w(fancybox)
		})
  end

	def texts
	end

	def images
	end

	def rendered_video
	end

	def rendered_video_thumb
	end

	private
		def set_dynamic_aae_project
			@dynamic_aae_project = Templates::DynamicAaeProject.find(params[:dynamic_aae_project_id])
		end

		def set_iconed_columns
			@iconed_columns = {#rendered_video_thumb: "image",
				#rendered_video: "youtube-play",
				texts: "file-text",
				images: "file-image-o"}
		end
end
