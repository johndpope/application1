class Templates::AaeProjectsController < ApplicationController
  include GenericCrudOperations
  include Templates::AaeProjectTextConcern

  before_action :set_aae_project, only: %w(preview_thumbnail preview_video)
  before_action :set_aae_project_text_types, only: %w(new edit)

  def initialize
		super
    init_settings({
			clazz: ::Templates::AaeProject,
		  view_folder: "templates/aae_projects",
			large_form: true,
			item_params: [:id,
        :name,
        :title,
        :project_type,
        :sub_dir,
        :xml,
        :description,
        :notes,
        :is_approved,
				:is_active,
        :is_special,
        :thumbnail,
        :video,
        :screenshot_time,
        aae_project_texts_attributes: [:id, :name, :value, :encoded_value, :is_static, :text_type],
        aae_project_images_attributes: [:id, :width, :height, :media_type, :image_type, :file_name]],
			index_table_header: I18n.t('templates.aae_project.aae_projects_list'),
			index_page_header: I18n.t('templates.aae_project.aae_projects'),
      index_title: 'Templates',
      index_small_header: 'AAE Projects',
      javascripts: %w(jquery.remotipart fancybox),
      stylesheets: %w(fancybox)
		})
  end

  def preview_thumbnail
    respond_to{|format| format.js}
  end

  def preview_video
    respond_to{|format| format.js}
  end

  private
    def set_aae_project
      @item = Templates::AaeProject.find params[:aae_project_id]
    end
end
