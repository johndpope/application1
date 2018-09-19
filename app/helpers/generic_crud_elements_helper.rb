module GenericCrudElementsHelper
	#options:
	#  body_url
	#  form_url
	#  search
	def generic_search_box(options={})
		render partial: "generic_crud_elements/search_box", locals: {options: options}
	end

	def generic_after_create_callback(item)
		render "generic_crud_elements/create", locals: {item: item}
	end

	def generic_after_update_callback(item)
		render "generic_crud_elements/update", locals: {item: item}
	end

	def generic_after_destroy_callback(item)
		render "generic_crud_elements/destroy", locals: {item: item}
	end

	def generic_form_dialog(item)
		render partial: "generic_crud_elements/form_dialog", locals: {item: item}
	end
end
