require 'rails_helper'

RSpec.describe Contract, type: :model do
  let(:contract) {Contract.new}

  describe '.attributes' do
    %w(id execution_date start_date end_date 
      evergreen_provision setup_period video_posting_start_date video_posting_end_date 
      amendment_date youtube_channel_names_approval youtube_channel_descriptions_approval 
      youtube_channel_art_approval youtube_channel_icon_approval youtube_video_titles_approval 
      youtube_video_descriptions_approval youtube_video_tags_approval youtube_video_custom_thumbnails_approval 
      youtube_channel_tags_approval video_production_templates_approval media_storage_images_approval 
      google_plus_cover_photos_approval client_images_supply client_logos_supply client_videos_supply 
      client_music_supply client_subject_video_supply_date client_id product_id parent_id).each do |a|
      it(a) { expect(contract).to respond_to(a) }
    end
  end
end
