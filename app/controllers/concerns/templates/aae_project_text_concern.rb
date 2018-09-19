extend ActiveSupport::Concern
module Templates
	module AaeProjectTextConcern
		def set_aae_project_text_types
      @project_text_types = Templates::AaeProjectText::TEXT_GROUPES.select{|ptk,ptv| ptk}.sort.map{
        |k,v|[I18n.t("templates.aae_project_text.groupes.#{k}"),v.map{
          |e|[I18n.t("templates.aae_project_text.types.#{e}"),Templates::AaeProjectText::TEXT_TYPES.select{
            |tk,tv|tk == e}.first.last, {'data-project-type' => e.to_s, 'data-text-type-limit' => Templates::AaeProjectText::TEXT_GROUPES_LIMITS[k][e]}]}]}
    end
	end
end
