require 'rails_helper'

RSpec.describe AdwordsCampaignGroup, type: :model do
  let(:adwords_campaign_group) { AdwordsCampaignGroup.new }

 describe '.attributes' do
  %w(name video_ad_url video_ad_format display_url final_url ad_name headline
	description_1 description_2 ready linked adwords_campaign_id youtube_video_id).each do |a|
      it(a) { expect(adwords_campaign_group).to respond_to(a) }
    end
  end
end
