class VideoSetBlender
    def self.create_blended_video(video_set, source_video, location, track_blended_components = true, trusted_video_ids = {})
        #blended_video = (track_blended_components == true ? BlendedVideo.create!(location: location, source_video: source_video) : nil)
        file_chunks_to_blend = []
        client_id = video_set.client.id
        #project_dynamic_text_ids = Templates::AaeProjectDynamicText.where("subject_video_id = ? OR (subject_video_id IS NULL AND client_id = ?)", source_video.id, client_id).pluck(:id)
        #dynamic_project_text_ids = Templates::DynamicAaeProjectText.where(aae_project_text_id: text_ids).pluck(:id)

        blending_patterns = [[:introduction, :summary_points, :bridge_to_subject, :source_video, :call_to_action, :social_networks, :likes_and_views, :ending],
            [:collage, :bridge_to_subject, :subject_video, :summary_points, :social_networks, :likes_and_views, :ending]]

        blending_pattern = blending_patterns[rand(0..1)]
        blending_pattern.each do |bp|
            if bp == :source_video && !source_video.blank?
                file_chunks_to_blend << source_video.video.path
            else
                if !trusted_video_ids[bp].blank?
                    video = Sandbox::Video.find_by_id(trusted_video_ids[bp])
                    file_chunks_to_blend << video.video.path unless video.video.blank?
                elsif !video_set.blank? && video = video_set.videos.with_video_type(bp).
                                                        where("location_id = ? AND location_type = ?", location.id, location.class.name).
                                                        where("is_approved IS NOT FALSE AND is_active IS NOT FALSE").
                                                        order('RANDOM()').first
                    file_chunks_to_blend << video.video.path
                end
            end
        end

        blending_dir = FileUtils.mkdir_p "/tmp/broadcaster/blending"
        blended_file = VideoTools::VideoBlender.new(videos: file_chunks_to_blend).blend
        blended_file.write(File.join(blending_dir, "#{SecureRandom.uuid}.mp4"))
    end
end
