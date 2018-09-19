class Templates::AaeProjectImage < ActiveRecord::Base
	include Reversible
	belongs_to :aae_project, foreign_key: :aae_project_id, class_name: "Templates::AaeProject"

	IMAGE_TYPES = {location_image: 1, client_logo: 2, client_secondary_logo: 5, subject_image: 3, client_image: 4}
	MEDIA_TYPES = {jpg: 1, png: 2, gif: 3}
	extend Enumerize
	enumerize :media_type, in: MEDIA_TYPES, scope: true
	extend Enumerize
	enumerize :image_type, in: IMAGE_TYPES, scope: true

	validates :width, :numericality => { :greater_than_or_equal_to => 200, :less_than_or_equal_to => 4000 }
	validates :height, :numericality => { :greater_than_or_equal_to => 200, :less_than_or_equal_to => 3000 }
	validates :file_name, presence: true, allow_blank: false
	validates :aae_project_id, presence: true, allow_blank: false

	default_scope{order(id: :desc)}

	before_save do
		self.media_type = File.extname(file_name).gsub('.', '')	unless file_name.blank?
	end

	def presents_in_project!
		self.presents_in_project = presents_in_project?
	end

	def presents_in_project?
		self.try(:aae_project).try(:xml).to_s.include?(file_name)
	end

	before_save :on_before_save

	private
		def on_before_save
			ActiveRecord::Base.transaction do
				if(file_name_changed? || aae_project_id_changed?)
					#remove existing delayed jobs
					Delayed::Job.
						where("(queue = ? OR queue = ?) AND handler like ?",
							DelayedJobQueue::TEMPLATES_AAE_PROJECT_VALIDATE_TEXTS,
							DelayedJobQueue::TEMPLATES_AAE_PROJECT_VALIDATE_IMAGES,
							"%aae_project_id: '#{aae_project.id}'%").each do |dj|
								dj.delete
					end

					#delayed job for text validation
					Delayed::Job.enqueue Templates::AaeProjects::ValidateTextLayersJob.new(aae_project.id.to_s),
						queue: DelayedJobQueue::TEMPLATES_AAE_PROJECT_VALIDATE_TEXTS
					#delayed jobs for image validation
					Delayed::Job.enqueue Templates::AaeProjects::ValidateImagesJob.new(aae_project.id.to_s),
						queue: DelayedJobQueue::TEMPLATES_AAE_PROJECT_VALIDATE_IMAGES

					aae_project.content_lock = true
					aae_project.save!
				end
			end
		end
end
