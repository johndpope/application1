ActiveAdmin.register UploadYoutubeVideo do
	menu :parent=>'Broadcasting'

	controller do
		def permitted_params()
			params.permit(upload_youtube_video:[
				:title,
				:description,
				:tags,
				:privacy,
				:category,
				:license_type,
				:certification,
				:allow_embedding,
				:notify_subscribers,
				:enable_age_restriction,
			])
		end
	end
end
