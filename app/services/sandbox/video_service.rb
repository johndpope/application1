module Sandbox
	class VideoService
		class << self
			def generate_video(source_video_id:nil, sandbox_video_set_id:nil, location_type:'Geobase::Locality', location_id:nil, rendering_machine_id:nil, aae_template_id:nil)
				params = method(__method__).parameters.map(&:last)
				opts = params.map { |p| [p, eval(p.to_s)] }.to_h
				opts.each do |name, value|
					raise "Parameter #{name} cannot be nil" if value.nil?
				end

				source_video = SourceVideo.find(source_video_id)
				sandbox_client = Sandbox::Client.find_by_client_id!(source_video.client.id)
				aae_template = Templates::AaeProject.find(aae_template_id)

				ActiveRecord::Base.transaction do
					dynamic_aae_project = Templates::DynamicAaeProject.create! target: 'sandbox',
						source_video_id: source_video_id,
						client_product_id: source_video.product_id,
						aae_project_id: aae_template.id,
						location_id: location_id, location_type: location_type,
						rendering_machine_id: rendering_machine_id,
						target: 'sandbox'
					sandbox_video = Sandbox::Video.create! sandbox_video_set_id: sandbox_video_set_id,
						source_video_id: source_video_id,
						video_type: aae_template.project_type,
						templates_aae_project_id: aae_template.id,
						templates_dynamic_aae_project_id: dynamic_aae_project.id,
						location_type: location_type,
						location_id: location_id,
						title: "#{I18n.t("templates.video_types.#{aae_template.project_type}")} #{dynamic_aae_project.id}"

						Delayed::Job.enqueue Templates::DynamicAaeProjects::SandboxProjectGenerationJob.new(dynamic_aae_project.id),
							queue: Templates::DynamicAaeProjects::SandboxProjectGenerationJob.get_queue_name
				end

				return true
			end

			def generate_videos(sandbox_video_set_id: nil, source_video_id: nil, location_type: 'Geobase::Locality', location_id: nil, rendering_machine_id: nil, items_per_template_type: 5, aae_template_type:nil)
				params = method(__method__).parameters.map(&:last)
				opts = params.map { |p| [p, eval(p.to_s)] }.to_h
				opts.each do |name, value|
					raise "Parameter #{name} cannot be nil" if value.nil?
				end

				source_video = SourceVideo.find(source_video_id)
				sandbox_client = Sandbox::Client.find_by_client_id!(source_video.client.id)
				sandbox_video_criteria = Sandbox::Video.
					where(sandbox_video_set_id: sandbox_video_set_id, location_id: location_id, location_type: location_type).
					with_video_type(aae_template_type)

				ActiveRecord::Base.transaction do
					ignored_aae_templates = sandbox_video_criteria.pluck(:templates_aae_project_id).uniq.reject(&:blank?)					
					1.upto(items_per_template_type)	do
						if aae_template = Templates::AaeTemplateService.random_template(aae_template_type, source_video.client.id, ignore: ignored_aae_templates)
							generate_video source_video_id: source_video_id, sandbox_video_set_id: sandbox_video_set_id,location_type: location_type, location_id: location_id, rendering_machine_id: rendering_machine_id, aae_template_id: aae_template.id
							ignored_aae_templates = ignored_aae_templates + sandbox_video_criteria.pluck(:templates_aae_project_id).uniq.reject(&:blank?)
						end
					end
				end

				return true
			end
		end
	end
end
