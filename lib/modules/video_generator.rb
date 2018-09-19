require 'fileutils'

module VideoGenerator	
	def self.generate(video_files, soundtrack = nil)
		uuid = SecureRandom.uuid
		video_dir = "/tmp/video_generator/#{uuid}"
		FileUtils.mkdir_p video_dir unless File.directory? video_dir
		
		stitched_videos = File.join("#{video_dir}", 'stitched_videos.mp4')
		output = File.join("#{video_dir}",'output.mp4')

		video_time = 0
		video_chunks = []		
		video_files.each do |v| 
			video_time = video_time + %x(ffprobe -show_format #{v} | grep -F duration | cut -d= -f2).to_f		
			video_chunks << "-cat #{v}"
		end

		mp3 = nil

		if soundtrack
			sound_overlay = File.join("#{video_dir}",'sound_overlay.mp3')

			soundtrack_time = %x(ffprobe -show_format #{soundtrack} | grep -F duration | cut -d= -f2).to_f

			if soundtrack_time < video_time
				i = video_time / soundtrack_time + (video_time % soundtrack_time > 0 ? 1 : 0)			

				soundtrack_chunks = "-cat #{soundtrack} "*i
				%x(MP4Box -new -force-cat #{soundtrack_chunks} #{sound_overlay})
			end

			mp3 = File.exists?(sound_overlay) ? sound_overlay : soundtrack
		end

		%x(MP4Box -new -force-cat #{video_chunks.join(' ')} #{stitched_videos})						
		%x(ffmpeg -i #{stitched_videos} -i #{mp3} -map 0:0 -map 1:0 -vcodec libx264 -acodec copy -shortest -strict experimental #{output}) if soundtrack
	end

	def self.generate_video_from_image(image_path, duration)
		video_dir = "/tmp/video_generator/from_image"
		output = File.join(video_dir, 'out.mp4')
		FileUtils.mkdir_p video_dir unless File.directory? video_dir

		%x(ffmpeg -loop 1 -i #{image} -vcodec libx264 -t 30 #{output})
	end
end