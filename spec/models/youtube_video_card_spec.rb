require 'rails_helper'

RSpec.describe YoutubeVideoCard, type: :model do
  let(:youtube_video_card) { YoutubeVideoCard.new }

 describe '.attributes' do
  %w(card_type url custom_message teaser_text youtube_video_id linked ready call_to_action card_title card_image).each do |a|
      it(a) { expect(youtube_video_card).to respond_to(a) }
    end
  end
end
