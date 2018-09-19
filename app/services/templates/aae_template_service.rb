module Templates::AaeTemplateService
	class << self
		def random_template(project_type, client_id, ignore:[])
			client = Client.find(client_id)
			criteria = {}
			if project_type == 'credits'
				credits_templates_with_client_disclaimer = Templates::AaeProject.
					with_project_type(project_type).
					ransack({aae_project_texts_text_type_eq: Templates::AaeProjectText::TEXT_TYPES[:credits_client_disclaimer]}).
					result.
					pluck(:id)
				credits_criteria_part = Templates::AaeProjectDynamicText.
					with_text_type(:credits_client_disclaimer).
					where(client_id: client_id).exists? ? '' : 'not_'
				criteria["id_#{credits_criteria_part}in"] = credits_templates_with_client_disclaimer
			end
			excluded_templates = Templates::AaeProjectOptOut.
				where(client_id: client_id).
				pluck(:templates_aae_project_id)
			if client.ignore_special_templates?
				excluded_templates = excluded_templates + Templates::AaeProject.where("is_special IS TRUE").pluck(:id)
			end
			return Templates::AaeProject.with_project_type(project_type).
				where('xml_file_name IS NOT NULL').
				where('is_approved IS TRUE').
				where('is_active IS TRUE').
				where('content_validation IS NOT FALSE AND content_lock IS NOT TRUE').
				where.not(id: excluded_templates).
				where.not(id: ignore).
				ransack(criteria).result.order('RANDOM()').first
		end

		def check_templates_master_folder_accessibility

		end
	end
end
