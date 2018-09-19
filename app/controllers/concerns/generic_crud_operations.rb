module GenericCrudOperations
	extend ActiveSupport::Concern
	include GenericCrudElementsHelper

	included do
		before_action :set_item, only: [:edit, :update, :destroy]
		before_action :before_index, only: :index
	end

	def index
		respond_to do |format|
			format.html{index_page @items}
			format.json{
				render json: {
					total: @items.total_count,
					items: @items.as_json(@index_json_conversion_options)
				}
			}
		end
	end

	def new
		@item = @clazz.new
		form_dialog @item
	end

	def edit
		form_dialog @item
	end

	def create
		@item = @clazz.new(item_params)
		if @item.save
			create_item @item
		else
			form_dialog @item
		end
	end

	def update
		if @item.update_attributes(item_params)
			update_item @item
		else
			form_dialog @item
		end
	end

	def destroy
		@item.destroy!
		destroy_item @item
	end

	def init_settings(settings = {})
		default_settings = {large_form: false,
			show_action_bar: true,
			show_add_button: true,
			show_edit_button: true,
			show_delete_button: true,
			show_info_button: false,
			javascripts: [],
			stylesheets: [],
			index_json_conversion_options: {only: [:id]},
			index_search_sorts: 'id desc',
			index_title: nil,
			index_small_header: nil,
			breadcrumbs: {}}
		settings = default_settings.merge settings
		@base_crud_path = "generic_crud_elements"
		@page_limit = 50
		@clazz = settings[:clazz]
		@view_folder = settings[:view_folder]
		@form_body = settings[:form_body]
		@large_form = settings[:large_form]
		@item_params = settings[:item_params]
		@index_table_header = settings[:index_table_header]
		@index_page_header = settings[:index_page_header]
		@show_action_bar = settings[:show_action_bar]
		@show_add_button = settings[:show_add_button]
		@show_edit_button = settings[:show_edit_button]
		@show_delete_button = settings[:show_delete_button]
		@show_info_button = settings[:show_info_button]
		@javascripts = settings[:javascripts]
		@stylesheets = settings[:stylesheets]
		@index_json_conversion_options = settings[:index_json_conversion_options]
		@index_search_sorts = settings[:index_search_sorts]
		@index_title = settings[:index_title]
		@index_small_header = settings[:index_small_header]
		@breadcrumbs = settings[:breadcrumbs]
	end

	def set_item
		@item = @clazz.find(params[:id])
	end

	def item_params
		params.require(@clazz.to_s.underscore.gsub('/','_')).permit(@item_params)
	end

	def index_page(index_options = {})
		render File.join(@base_crud_path, "index"), locals: {index_options: index_options}
	end

	def form_dialog(item)
		generic_form_dialog(item)
	end

	def create_item(item)
		generic_after_create_callback(item)
	end

	def update_item(item)
		generic_after_update_callback(item)
	end

	def destroy_item(item)
		generic_after_destroy_callback(item)
	end

	private
		def before_index
			@search = @clazz.search(params[:q])
			@search.sorts = @index_search_sorts
			@items = @search.result.page(params[:page]).per(@page_limit)
		end
end
