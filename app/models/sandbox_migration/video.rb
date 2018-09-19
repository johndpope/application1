module SandboxMigration
  class Video < ActiveRecord::Base
    use_connection_ninja(:sandbox)

      VIDEO_TYPES = {introduction: 1, subject: 2, ending: 3, collage: 4, bridge_to_subject: 5, credits: 6, call_to_action: 7, summary_points: 8,likes_and_views: 11, social_networks: 12}
      VIDEO_TYPES_ORDERS = {introduction: 1, bridge_to_subject: 2, subject: 3, collage: 4, summary_points: 5, call_to_action: 6, ending: 7, likes_and_views: 8, social_networks: 9, credits: 10}

      extend Enumerize
      enumerize :video_type, in: VIDEO_TYPES, scope: :having_video_type

      has_attached_file :video,
          path: ":rails_root/public/system/videos/video_chunks/:id_partition/:style/:basename.:extension",
          url:  "/system/videos/video_chunks/:id_partition/:style/:basename.:extension"

      validates_attachment :video, allow_blank: true,
          content_type: {content_type: ['video/mp4'], message: 'Invalid content type'},
          size: {greater_than: 0.bytes, less_than: 500.megabytes, message: 'File size exceeds the limit allowed'}

      has_attached_file :thumb,
          path: ":rails_root/public/system/images/video_chunk_thumbnails/:id_partition/:style/:basename.:extension",
          url:  "/system/images/video_chunk_thumbnails/:id_partition/:style/:basename.:extension",
          styles: {thumb: "240x180>", medium: "640x480>"}

      validates_attachment :thumb, allow_blank: true,
          content_type: {content_type: ['image/png','image/jpeg', 'image/gif'], message: 'Invalid content type'},
          size: {greater_than: 0.bytes, less_than: 1.megabytes, message: 'File size exceeds the limit allowed'}

      before_save :set_title

      before_video_post_process :urlify_file_name
      after_video_post_process :set_media_info

      include Videable
  end
end
