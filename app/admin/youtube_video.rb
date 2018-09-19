ActiveAdmin.register YoutubeVideo do
  menu parent: 'Google'

  	filter :id, as: :string
  	filter :source_video, as: :select, collection: SourceVideo.order(:video_file_name)
  	filter :youtube_channel_google_account_email, as: :string, label: 'gmail'
  	filter :youtube_channel_google_account_is_active, as: :check_boxes, label: 'gmail is active'

	index do		
	  selectable_column
		column :id
		#column do
		#	image_tag 'youtube.png', class: 'youtube-icon', title: "Play this video", alt: "Play"
		#end
		column 'Google Account' do |youtube_video|
			youtube_video.youtube_channel.google_account.email
		end		
		column 'Thumb' do |youtube_video|
			image_tag youtube_video.thumbnail_urls[:default], class: 'youtube-video-thumbnail'
		end
		column :title do |youtube_video|
			link_to(youtube_video.title,youtube_video.url)
		end
		column 'Description' do |youtube_video|
			div class: 'limited fluent-wrapper' do
				div class: 'fluent-container', id: "youtube_video_description_#{youtube_video.id}" do
					youtube_video.description
				end
			end
		end
		column label: 'Tags', span: 2 do |youtube_video|
			div :class=>'limited fluent-wrapper' do
				div class: 'fluent-container' do
					youtube_video.splitted_tags.each {|tag| status_tag(tag, :ok, class:'youtube-video-tag')}
				end
			end
		end
		column :publication_date		
		actions
  	end  

  controller do
    def permitted_params
      params.permit(youtube_video: [:title, :description, :publication_date, :youtube_channel_id, :source_video_id])
    end
  end
end
