module Videable
  extend ActiveSupport::Concern

  included do
      belongs_to :client
      belongs_to :video_set
      belongs_to :locality, foreign_key: 'locality_id', class_name: 'Geobase::Locality'

      serialize :media_info, Mediainfo

      before_save :set_title

      has_one :video_media_info, as: :resource, dependent: :destroy
  end

  def display_name
      video_file_name
  end

  def get_video_duration
     unless self.video.blank?
          result = `ffmpeg -i #{self.video.path} 2>&1`
          r = result.match("Duration: ([0-9]+):([0-9]+):([0-9]+).([0-9]+)")
          if r
              self.duration = r[1].to_i*3600+r[2].to_i*60+r[3].to_i
          end
      end
  end

  def set_default_stream_order
      return if self.video.blank? || self.video_file_name.blank? || !File.exists?(self.video.path)
      media_info = Mediainfo.new self.video.path
      return if media_info.video.parsed_response[:video]["id"].to_i == 1

      if self.video_file_name.include? "'"
          self.urlify_file_name
          self.save
          self.reload!
      end
      file_path = File.join('/tmp', self.video_file_name)
      %x(ffmpeg -i '#{self.video.path}' -vcodec copy -acodec copy -y '#{file_path}')

      self.video = File.open(file_path)
      self.save!
      FileUtils.rm_f(file_path)
      nil
  end

  def urlify_file_name
    extension = File.extname(self.video_file_name).gsub(/^\.+/, '')
    filename = self.video_file_name.gsub(/\.#{extension}$/, '')
    self.video.instance_write(:file_name, "#{filename.to_url}.#{extension}")
  end

  def set_title
    self.title = File.basename(video_file_name,File.extname(video_file_name)).titleize if !video_file_name.blank? && title.blank?
  end

  def set_media_info
      media_info = Mediainfo.new self.video.queued_for_write[:original].path
      self.media_info = media_info
      self.duration = media_info.video[0].duration / 1000
  end
end
