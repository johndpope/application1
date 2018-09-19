module SandboxMigration
  class VideoSet < ActiveRecord::Base
      use_connection_ninja(:sandbox)

      belongs_to :client
      has_one :video_media_info, as: :resource, dependent: :destroy
      has_many :videos
      has_many :transitions

      accepts_nested_attributes_for :video_media_info

      validates_presence_of :title

      has_attached_file :thumb,
          path: ":rails_root/public/system/images/video_set_thumbnails/:id_partition/:style/:basename.:extension",
          url:  "/system/images/video_set_thumbnails/:id_partition/:style/:basename.:extension",
          styles: {thumb: "120x90>", medium: "640x480>"}

      validates_attachment :thumb, allow_blank: true,
          content_type: {content_type: ['image/png','image/jpeg', 'image/gif'], message: 'Invalid content type'},
          size: {greater_than: 0.bytes, less_than: 1.megabytes, message: 'File size exceeds the limit allowed'}

      has_attached_file :blended_sample,
          path: ":rails_root/public/system/videos/blended_samples/:id_partition/:style/:basename.:extension",
          url:  "/system/videos/blended_samples/:id_partition/:style/:basename.:extension"

      validates_attachment :blended_sample, allow_blank: true,
          content_type: {content_type: ['video/mp4'], message: 'Invalid content type'},
          size: {greater_than: 0.bytes, less_than: 500.megabytes, message: 'File size exceeds the limit allowed'}

      def name
          title
      end

      def ordered_videos
          videos = Video.where(video_set_id: self.id).where('is_active IS NOT FALSE').order(:order_nr).order(:video_file_name)
          order_nrs = videos.pluck(:order_nr)
          res = {}
          order_nrs.each do |on|
            res[on] = videos.map{|v| v if v.try(:order_nr) == on}.compact
          end
          res
      end

      def videos_grouped_by_type
          videos = Video.where(video_set_id: self.id).where('is_active IS NOT FALSE').order(:video_type).order(:video_file_name)
          video_types = videos.pluck(:video_type)
          res = {}
          video_types.each do |vt|
              res[vt] = videos.map{|v| v if v.video_type.try(:value) == vt}.compact
          end
          res
      end

      def transitions_grouped_by_type
          videos = Transition.where(video_set_id: self.id).where('is_active IS NOT FALSE').order(:video_type).order(:video_file_name)
          video_types = videos.pluck(:video_type)
          res = {}
          video_types.each do |vt|
              res[vt] = videos.map{|v| v if v.video_type.try(:value) == vt}.compact
          end
          res
      end
  end
end
