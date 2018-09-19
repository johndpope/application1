namespace :templates do
	namespace :dynamic_aae_projects do
		task check_rendered_video_file_existance: :environment do |t, args|
			if Templates::DynamicAaeProject.where(rendered_video_file_exists: nil).exists?
				unless Delayed::Job.
					where(queue: 'Templates::DynamicAaeProjects::CheckRenderedVideoFileExistanceJob').
					where(attempts: 0).
					exists?
					Templates::DynamicAaeProject.unscoped.where(rendered_video_file_exists: nil).find_in_batches do |batch|
						ActiveRecord::Base.transaction do
							batch.each do |dp|
		            Delayed::Job.enqueue Templates::DynamicAaeProjects::CheckRenderedVideoFileExistanceJob.new(dp.id),
									queue: "Templates::DynamicAaeProjects::CheckRenderedVideoFileExistanceJob",
									priority: DelayedJobPriority::HIGH
		          end
						end
					end
				end
			end
		end
	end
end
