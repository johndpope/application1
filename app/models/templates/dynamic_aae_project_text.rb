class Templates::DynamicAaeProjectText < ActiveRecord::Base
	include Reversible
	
	belongs_to :dynamic_aae_project,
		class_name: "Templates::DynamicAaeProject",
		foreign_key: "dynamic_aae_project_id"
	belongs_to :aae_project_text,
		class_name: "Templates::AaeProjectText",
		foreign_key: "aae_project_text_id"
	has_one :aae_project, through: :dynamic_aae_project
end
