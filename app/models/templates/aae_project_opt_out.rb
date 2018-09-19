class Templates::AaeProjectOptOut < ActiveRecord::Base
	include Reversible
	belongs_to :client
	belongs_to :aae_project, class_name: "Templates::AaeProject", foreign_key: "templates_aae_project_id"
	validates_presence_of :client_id
	validates_presence_of :templates_aae_project_id
	validates_uniqueness_of :client_id, scope: :templates_aae_project_id, message: "and AAE Project have already been taken"
end
