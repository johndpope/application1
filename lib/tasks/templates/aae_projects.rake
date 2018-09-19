namespace :templates do
	namespace :aae_projects do
		task :validate_project_texts, [:project_id] => :environment do |t,args|
			Delayed::Job.enqueue Templates::AaeProjects::ValidateTextLayersJob.new(args['project_id']),
				queue: DelayedJobQueue::TEMPLATES_AAE_PROJECT_VALIDATE_TEXTS
		end

		task :validate_projects_texts => :environment do |t,args|
			ActiveRecord::Base.transaction do
				Templates::AaeProject.all.each do |t|
					Delayed::Job.enqueue Templates::AaeProjects::ValidateTextLayersJob.new(t.id),
						queue: DelayedJobQueue::TEMPLATES_AAE_PROJECT_VALIDATE_TEXTS
				end
			end
		end

		task :validate_project_images, [:project_id] => :environment do |t,args|
			Delayed::Job.enqueue Templates::AaeProjects::ValidateImagesJob.new(args['project_id']),
				queue: DelayedJobQueue::TEMPLATES_AAE_PROJECT_VALIDATE_IMAGES
		end

		task :validate_projects_images => :environment do |t,args|
			ActiveRecord::Base.transaction do
				Templates::AaeProject.all.each do |t|
					Delayed::Job.enqueue Templates::AaeProjects::ValidateImagesJob.new(t.id),
						queue: DelayedJobQueue::TEMPLATES_AAE_PROJECT_VALIDATE_IMAGES
				end
			end
		end

		task :validate_project_content, [:project_id] => :environment do |t, args|
			ActiveRecord::Base.transaction do
				Delayed::Job.enqueue Templates::AaeProjects::ValidateTextLayersJob.new(args['project_id']),
					queue: DelayedJobQueue::TEMPLATES_AAE_PROJECT_VALIDATE_TEXTS
				Delayed::Job.enqueue Templates::AaeProjects::ValidateImagesJob.new(args['project_id']),
					queue: DelayedJobQueue::TEMPLATES_AAE_PROJECT_VALIDATE_IMAGES
			end
		end

		task :validate_projects_content => :environment do |t, args|
			ActiveRecord::Base.transaction do
				Templates::AaeProject.all.each do |t|
					Delayed::Job.enqueue Templates::AaeProjects::ValidateTextLayersJob.new(t.id),
						queue: DelayedJobQueue::TEMPLATES_AAE_PROJECT_VALIDATE_TEXTS
					Delayed::Job.enqueue Templates::AaeProjects::ValidateImagesJob.new(t.id),
						queue: DelayedJobQueue::TEMPLATES_AAE_PROJECT_VALIDATE_IMAGES
				end
			end
		end
	end
end
