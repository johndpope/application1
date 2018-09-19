module Templates::DynamicAaeProjectService
	class << self
		def generate_test_project(aae_template_id, rendering_machine_id, params = {})
			location = if params.key?(:location)
									"#{params[:location][:type]}".constantize.find(params[:location][:id])
								else #default location - San Francisco, California
									state_id = Geobase::Region.find_by_name('California')
									Geobase::Locality.find_by_primary_region_id_and_name(state_id, 'San Francisco')
								end
			criteria = {}
			criteria[:client_id_eq] = params[:client_id] unless params[:client_id].blank?
			criteria[:product_id_eq] = params[:product_id] unless params[:product_id].blank?
			criteria[:id_eq] = params[:subject_video_id] unless params[:subject_video_id].blank?

			subject_video = SourceVideo.order('RANDOM()').ransack(criteria).result.first
			product = subject_video.product
			client = subject_video.client

			Templates::DynamicAaeProject.with_target(:test).where(aae_project_id: aae_template_id).each do |dp|
				dp.destroy!
			end

			dynamic_aae_project = Templates::DynamicAaeProject.create! aae_project_id: aae_template_id,
				target: 'test',
				client_product_id: subject_video.product.id,
				source_video_id: subject_video.id,
				location_id: location.id,
				location_type: location.class.name,
				rendering_machine_id: rendering_machine_id

			Delayed::Job.
				where(queue: Templates::DynamicAaeProjects::TestProjectGenerationJob.get_queue_name).
				where("handler like ?", "%aae_template_id: '#{aae_template_id}'%").
				each{|dj| dj.delete}

			Delayed::Job.enqueue Templates::DynamicAaeProjects::TestProjectGenerationJob.new(dynamic_aae_project.id),
				queue: Templates::DynamicAaeProjects::TestProjectGenerationJob.get_queue_name
		end
	end
end
