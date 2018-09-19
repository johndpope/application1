require 'rails_helper'

RSpec.describe YoutubeVideoCardTemplate, type: :model do
  let(:youtube_video_card_template) { YoutubeVideoCardTemplate.new }

 describe '.attributes' do
  %w(card_type url custom_message teaser_text youtube_setup_id linked ready).each do |a|
      it(a) { expect(youtube_video_card_template).to respond_to(a) }
    end
  end
end
