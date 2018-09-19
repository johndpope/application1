require 'rails_helper'

RSpec.describe WatchingVideoCategory, type: :model do
  let(:watching_video_category) {WatchingVideoCategory.new}
  describe '.attributes' do
    %w(name phrases).each do |a|
      it(a) { expect(watching_video_category).to respond_to(a) }
    end
  end
end
