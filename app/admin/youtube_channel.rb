ActiveAdmin.register YoutubeChannel do
  menu parent: 'Google'

  index do
  	selectable_column
  	column :id
  	column :youtube_channel_id
    column :youtube_channel_name
    column :channel_icon do |yc|
        image_tag(yc.channel_icon.url(:thumb)) unless yc.channel_icon.blank?
    end
    column :channel_art do |yc|
        image_tag(yc.channel_art.url(:thumb)) unless yc.channel_art.blank?
    end
  	column :google_account
    column :thumbnails_enabled
  	column :is_active
  	column :created_at
  	column :updated_at
  	actions
  end

  show do
  	attributes_table do
  		row :id
	  	row :youtube_channel_id
      row :youtube_channel_name
	  	row :google_account
      row :thumbnails_enabled
	  	row :is_active
	  	row :created_at
	  	row :updated_at
  	end
  	active_admin_comments
  end

  form do |f|
  	f.inputs 'Youtube Channel Details' do
  		f.input :google_account, :as=>:select
  		f.input :youtube_channel_id, :label=>'Youtube Channel ID'
      f.input :youtube_channel_name, :label=>'Youtube Channel Name'
      f.input :channel_type, as: :select, collection: YoutubeChannel::CHANNEL_TYPES, selected: (f.object.channel_type.blank? ? nil : f.object.channel_type.value)
      f.input :category, as: :select, collection: YoutubeChannel::CATEGORIES, selected: (f.object.category.blank? ? nil : f.object.category.value)
      f.input :thumbnails_enabled
      f.input :is_active
  	end
  	f.actions
  end

  permit_params :is_active, :youtube_channel_id, :youtube_channel_name, :google_account_id, :thumbnails_enabled, :category, :channel_type
end
