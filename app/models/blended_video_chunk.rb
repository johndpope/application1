class BlendedVideoChunk < ActiveRecord::Base
	include Reversible
	extend Enumerize

	belongs_to :blended_video, class_name: "BlendedVideo", foreign_key: "blended_video_id"
	has_one :source_video, through: :blended_video
	has_one :product, through: :source_video
	has_one :client, through: :product
	belongs_to :dynamic_aae_project,
		class_name: "Templates::DynamicAaeProject",
		foreign_key: "templates_dynamic_aae_project_id",
		dependent: :destroy
	has_one :aae_project, through: :dynamic_aae_project
	has_many :dynamic_aae_project_images,
		through: :dynamic_aae_project,
		class_name: "Templates::DynamicAaeProjectImage",
		foreign_key: "dynamic_aae_project_id"
	has_many :dynamic_aae_project_texts,
		through: :dynamic_aae_project,
		class_name: "Templates::DynamicAaeProjectText",
		foreign_key: "dynamic_aae_project_id"

	enumerize :chunk_type, in: Templates::VIDEO_TYPES, scope: true

	def subject?
		chunk_type == 'subject'
	end
end
