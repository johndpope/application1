require 'rails_helper'

RSpec.describe Reference, type: :model do
  let(:reference) { FactoryGirl.build(:reference) }
  
  describe '.attributes' do
    %w(url description group referer referer_id referer_type).each do |attribute|
      it("##{attribute}") { expect(reference).to respond_to(attribute) }
    end
  end

  describe '#url' do
    it 'has to be present' do
      expect(reference.url).to be_present
      expect(reference).to be_valid
      [nil, ''].each do |value|
        reference.url = value
        expect(reference).to_not be_valid
      end
    end
  end
end
