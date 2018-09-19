module VideoTools
  def get_time(file_path)
    %x(ffprobe -show_format #{file_path} | grep -F duration | cut -d= -f2).to_f
  end

  class VideoBlender
    DEFAULT_DIR = '/tmp/broadcaster/blended_videos'

    def initialize(params = {})
      @videos = params[:videos] || []
      @audios = params[:audios] || []
      @temp_output_dir = params[:temp_output_dir] || DEFAULT_DIR
      FileUtils.mkdir_p @temp_output_dir unless File.directory? @temp_output_dir
    end

    def blend
      return nil if @videos.to_a.empty?

      time = Time.now.strftime("%Y-%m-%d %H:%M:%S:%8N")
      temp_output_file = File.join(@temp_output_dir, "#{time}.mp4")

      video_chunks = @videos.each_with_index.map{|el, index| "#{index == 0 ? '-force-cat -cat' : '-cat'} \"#{el}\""}
      %x(MP4Box #{video_chunks.join(' ')} -new '#{temp_output_file}')

      return File.open(temp_output_file)
    end
  end
end
