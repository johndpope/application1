require 'rails_helper'

RSpec.describe Screenshot, type: :model do
  let(:screenshot) {Screenshot.new}
  describe '.attributes' do
    %w(screenshotable_id screenshotable_type image).each do |a|
      it(a) { expect(screenshot).to respond_to(a) }
    end
  end
end
