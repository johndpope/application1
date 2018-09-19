ActiveAdmin.register YoutubeChannelPlaylist do
	menu parent: 'Google'
	  
	form do |f|
	  	f.inputs 'Playlist Details' do
	  		f.input :name
	  		f.input :youtube_list_id, :label=>'Youtube Playlist ID'
	  		f.input :youtube_channel_id, :label=>'Youtube Channel ID (integer value)'
	  	end
	  	f.actions
  	end

  controller do
  	def permitted_params
  		params.permit(:youtube_channel_playlist=>[:name,:youtube_list_id, :youtube_channel_id])
  	end
  end
end
