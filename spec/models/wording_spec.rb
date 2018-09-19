require 'rails_helper'

RSpec.describe Wording, type: :model do
  let(:wording) { FactoryGirl.build(:wording) }

  describe '.attributes' do
    %w(name source spintax resource_id resource_type resource spins spun_at).each do |a|
      it(a) { expect(wording).to respond_to(a) }
    end
  end

  describe '#spintax' do
    it 'mixes in the SpintaxParser module' do
      expect(wording.spintax).to be_present
      expect(wording.spintax).to be_a(SpintaxParser)
    end
  end

  describe '#spins' do
    it 'is an Array' do
      expect(wording.spins).to be_an(Array)
    end
  end
end
