namespace :templates do
	namespace :dynamic_aae_projects do
		task :generate_test_project, [:aae_template_id, :rendering_machine_id, :params] => :environment do |t, args|
			ActiveRecord::Base.transaction do
				params = eval(args['params'].to_s.gsub(';', ',')).try(:symbolize_keys) || {}
				Templates::DynamicAaeProjectService.generate_test_project args['aae_template_id'], args['rendering_machine_id'], params
			end
		end
	end
end
