class Artifacts::HumanPhotosController < Artifacts::BaseController
	include GenericCrudOperations

	def initialize
    super
    init_settings({
      clazz: ::Artifacts::HumanPhoto,
      view_folder: "artifacts/human_photos",
      breadcrumbs: {name: :artifacts_human_photos},
			index_table_header: 'List of Human Photos',
			index_page_header: 'Human Photos',
      index_title: 'Human Photos',
			show_action_bar: false,
      javascripts: %w(fancybox),
			stylesheets: %w(fancybox)
    })
  end
end
