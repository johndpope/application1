module SandboxMigration
  class Transition < ActiveRecord::Base
    use_connection_ninja(:sandbox)

     VIDEO_TYPES = {simple_transition: 1, text_transition: 2, image_text_transition: 3}

      extend Enumerize
      enumerize :video_type, in: VIDEO_TYPES, scope: :having_video_type

      has_attached_file :thumb,
          path: ":rails_root/public/system/images/transition_thumbnails/:id_partition/:style/:basename.:extension",
          url:  "/system/images/transition_thumbnails/:id_partition/:style/:basename.:extension",
          styles: {thumb: "240x180>", medium: "640x480>"}

      validates_attachment :thumb, allow_blank: true,
          content_type: {content_type: ['image/png','image/jpeg', 'image/gif'], message: 'Invalid content type'},
          size: {greater_than: 0.bytes, less_than: 10.megabytes, message: 'File size exceeds the limit allowed'}

      has_attached_file :video,
          path: ":rails_root/public/system/videos/transitions/:id_partition/:style/:basename.:extension",
          url:  "/system/videos/transitions/:id_partition/:style/:basename.:extension"

      validates_attachment :video, allow_blank: true,
          content_type: {content_type: ['video/mp4'], message: 'Invalid content type'},
          size: {greater_than: 0.bytes, less_than: 500.megabytes, message: 'File size exceeds the limit allowed'}

      before_video_post_process :urlify_file_name
      after_video_post_process :set_media_info

      def name
          title
      end

      include Videable
  end
end
