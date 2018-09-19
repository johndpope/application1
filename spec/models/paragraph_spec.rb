require 'rails_helper'

RSpec.describe Paragraph, type: :model do
  let(:paragraph) { FactoryGirl.build(:paragraph) }

  describe '.attributes' do
    %w(title body scope resource_id resource_type resource position spintax spun_at).each do |f|
      it(f) { expect(paragraph).to respond_to(f) }
    end
  end
end
