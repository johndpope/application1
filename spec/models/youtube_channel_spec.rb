require 'rails_helper'

RSpec.describe YoutubeChannel, type: :model do
  let(:youtube_channel) { YoutubeChannel.new }

 describe '.attributes' do
  %w(youtube_channel_id is_active google_account_id
    youtube_channel_name keywords thumbnails_enabled
    is_verified_by_phone channel_icon channel_art
    overlay_google_plus description business_inquiries_email
    advertisements recommendations subscriber_counts
    channel_links linked phone_number notes category
    publication_date channel_type screenshots filled filling_date ready 
    fields_to_update posting_time).each do |a|
      it(a) { expect(youtube_channel).to respond_to(a) }
    end
  end
end
