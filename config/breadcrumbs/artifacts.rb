crumb :artifacts do
	link "Artifacts", artifacts_root_path
end

crumb :artifacts_dashboard do
	link t('dashboard'), artifacts_root_path
	parent :artifacts
end

crumb :artifacts_images_report_by_localities do
	link "Images report by localities", report_by_localities_artifacts_images_path
	parent :artifacts
end

crumb :artifacts_images_report_by_industries do
	link "Images report by industries", report_by_industries_artifacts_images_path
	parent :artifacts
end

crumb :artifacts_images_report_by_admin_users do
	link "Images report by admin users", report_by_admin_users_artifacts_images_path
	parent :artifacts
end

crumb :artifacts_image_storage do
	link "Image Storage", artifacts_images_path
	parent :artifacts
end

crumb :artifacts_image_upload do
	link t('artifacts.upload_local_files'), upload_artifacts_images_path
	parent :artifacts_image_storage
end

crumb :artifacts_image_blender do
  link t("artifacts.image_blender"), artifacts_image_blender_path
  parent :artifacts
end

crumb :artifacts_blended_images do
	link t("artifacts.blended_images"), artifacts_blended_images_path
	parent :artifacts
end

crumb :artifacts_audio_storage do
	link "Audio storage", artifacts_audios_path
	parent :artifacts
end

crumb :artifacts_audio_upload do
	link "Local upload", local_import_artifacts_audios_path
	parent :artifacts_audio_storage
end

crumb :artifacts_human_photos do
	link "Human Photos", artifacts_human_photos_path
	parent :artifacts
end
