class DelayedJobQueue
	ARTIFACTS_IMAGE_IMPORT = 'artifacts_image_import'
	ARTIFACTS_IMAGE_ASCPECT_CROPPING_VARIATIONS = 'artifacts_image_aspect_cropping_variations'
	ARTIFACTS_GENERATE_IMAGE_CROPPINGS = 'artifacts_generate_image_croppings'
	ARTIFACTS_FIX_ORIG_IMAGE_ORIENTATION = 'artifacts_fix_orig_image_orientation'
	ARTIFACTS_REPROCESS_IMAGE_THUMBNAIL = 'artifacts_reprocess_image_thumbnail'
	TEMPLATES_DYNAMIC_AAE_PROJECT_CREATE = 'templates_aae_project_create'
	TEMPLATES_DYNAMIC_AAE_PROJECT_REPLACE = 'templates_dynamic_aae_project_replace'
	RENDERING_MACHINE_TAKE_OUTPUT_VIDEO = 'rendering_machine_take_output_video'
	RENDERING_MACHINE_REMOVE_OUTPUT_VIDEO = 'rendering_machine_remove_output_video'
	RENDERING_MACHINE_SYNC_AME_LOG = 'rendering_machine_ame_log'
	RENDERING_MACHINE_GRAB_INFO = 'rendering_machine_grab_info'
	BLEND_VIDEO_SET = 'blend_video_set'
	FORCE_BLEND_VIDEO_SET = 'blended_videos_force_blend_video_set'
	TEMPLATES_AAE_PROJECT_VALIDATE_TEXTS = 'templates_aae_project_validate_texts'
	TEMPLATES_AAE_PROJECT_VALIDATE_IMAGES = 'templates_aae_project_validate_images'
  YOUTUBE_CREATE_VIDEO = 'youtube_create_video'
	YOUTUBE_CREATE_VIDEO_THUMBNAIL_FOR_GENERATED_VIDEO = 'youtube_create_video_thumbnail_for_generated_video'
	GENERATE_TEST_PROJECT_JOB = 'templates_dynamic_aae_project_generate_test_project_job'
	SAVE_PROFILE_CACHE = 'save_profile_cache'
	SAVE_SCREENSHOT = 'save_screenshot'
	GRAB_YOUTUBE_STATISTICS = 'grab_youtube_statistics'
	START_CHANNELS_PROCESS = 'start_channels_process'
	UPDATE_GEO_INFO = 'update_geo_info'
	CRAWLER_ADD_INFO = 'crawler_add_info'
  SOUNDTRACK = 'soundtrack'
  OTHER = 'other'
	CREATE_MEDIA_INFO = 'create_media_info'
  RETRIEVE_GPS_FROM_IMAGE_FILES = 'retrieve_gps_from_image_files'
  DEALERS_CRAWLING = "dealers_crawling"
  RECOVERY_INBOX_EMAILS = "recovery_inbox_emails"

  def self.set_empty_queues_as_other
    Delayed::Job.where(queue: nil).update_all(queue: DelayedJobQueue::OTHER)
  end
end
