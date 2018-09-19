require 'rails_helper'

RSpec.describe AdwordsCampaign, type: :model do
  let(:adwords_campaign) { AdwordsCampaign.new }

 describe '.attributes' do
  %w(name campaign_type campaign_subtype networks_youtube_search networks_youtube_videos
	networks_include_video_partners locations languages start_date end_date
	google_account_id linked ready).each do |a|
      it(a) { expect(adwords_campaign).to respond_to(a) }
    end
  end
end
