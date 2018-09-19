require 'rails_helper'

RSpec.describe CallToActionOverlay, type: :model do
  let(:call_to_action_overlay) { CallToActionOverlay.new }

 describe '.attributes' do
  %w(headline display_url destination_url enabled_on_mobile ready
	linked youtube_video_id).each do |a|
      it(a) { expect(call_to_action_overlay).to respond_to(a) }
    end
  end
end
