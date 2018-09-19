class VideoService
	BASE_DIR = "/tmp/broadcaster/video_service"
	class << self
		def extract_audio(src_video_path, output_audio_path, sampling_rate: '44100', bitrate: '192K')
			%x(ffmpeg -i "#{src_video_path}" -vn -ar #{sampling_rate} -ac 2 -ab #{bitrate} -f mp3 "#{output_audio_path}")
		end

		def overlay_fading!(src_audio_path, fade_in_start, fade_out_start, fade_time: 1)
			base_audio_fading_dir = File.join(BASE_DIR,  'audio', "fading")
			tmp_faded_audio_path = File.join(base_audio_fading_dir, "#{SecureRandom.hex}.mp3")
			begin
				FileUtils.mkdir_p base_audio_fading_dir
				audio_duration = get_duration(src_audio_path)
				raise "Fade time cannot negative" if fade_time < 0
				raise "Fade in/out start time cannot be negative" if fade_in_start < 0 || fade_out_start < 0
				raise "Fade in/out start time exceeds source audio duration" if fade_in_start > audio_duration || fade_out_start > audio_duration
				raise "Fade in/out end time exceeds source audio duration" if (fade_in_start+fade_time) > audio_duration || (fade_out_start+fade_time) > audio_duration
				# applies fading effects source audio and saves output to tmp audio file
				%x(ffmpeg -i "#{src_audio_path}" -af afade=t=in:st=#{fade_in_start}:d=#{fade_time},afade=t=out:st=#{fade_out_start}:d=#{fade_time} "#{tmp_faded_audio_path}")
				# replaces source audio file with tmp audio file
				FileUtils.cp_r tmp_faded_audio_path, src_audio_path, verbose: false
			rescue Exception => e
				raise e
			ensure
				FileUtils.rm_rf tmp_faded_audio_path
			end
		end

		def overlay_soundtrack(original_video_path, original_soundtrack_path, output_video_path, vcodec:'copy', acodec: 'copy', video_map: '0:v:0', audio_map: '1:a:0', use_experimental_codecs: true)
			%x(ffmpeg -i "#{original_video_path}" -i #{original_soundtrack_path} -vcodec #{vcodec} -acodec libmp3lame -map #{video_map} -map #{audio_map} #{use_experimental_codecs ? '-strict -2' : ''} #{output_video_path})
		end

		def get_duration(src_video_path)
			return %x(ffprobe -show_format "#{src_video_path}" | grep -F duration | cut -d= -f2).to_f
		end

		def join_videos(src_video_paths = [], output_video_path)
			cmd_parts = src_video_paths.each_with_index.map{|path, i| "#{i == 0 ? '-force-cat -cat' : '-cat'} \"#{path}\""}
			%x(MP4Box #{cmd_parts.join(' ')} -new '#{output_video_path}')
		end

		def join_audios(src_audio_paths, output_audio_path, acodec: 'libmp3lame', use_experimental_codecs: true)
			%x(avconv -i "concat:#{src_audio_paths.join('|')}" -acodec #{acodec} #{use_experimental_codecs ? '-strict -2' : ''} #{output_audio_path})
		end
	end
end
