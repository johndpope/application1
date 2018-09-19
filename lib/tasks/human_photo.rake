namespace :human_photo do
    desc "Import VK avatars"
  	task :import_vk, [:city, :sex, :age_from, :age_to, :count, :offset]=> :environment  do |t,args|
        options = {}
        args.each{|key, value| options[key] = value}

        api_result = Artifacts::VkPhoto::list options
        api_result[:items].each{|vk_photo| ActiveRecord::Base.transaction{vk_photo.save!; Artifacts::ImagesService.delay(queue: DelayedJobQueue::ARTIFACTS_IMAGE_IMPORT).import("VkPhoto", vk_photo.id)}}
	end
end
