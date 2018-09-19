crumb :user_scope do
	link "Shared media", shared_media_root_path
end

crumb :media_upload do
	link 'Upload files', shared_media_images_local_import_path
	parent :user_scope
end

crumb :media_browse do
	link 'Browse files', shared_media_images_browse_path
	parent :user_scope
end
