require 'rails_helper'

RSpec.describe Artifacts::SearchSuggestion do

  describe '.matching_to' do
    let(:landmark) { Geobase::Landmark.order('random()').first }

    it 'finds landmark names' do
      locality_name = landmark.locality.try(:name)
      region_name = landmark.locality.try(:primary_region).try(:name) || landmark.region.try(:name)
      phrase = [landmark.name, locality_name, region_name].select(&:present?).join(' ')
      phrases = described_class.matching_to(region_name).pluck('phrase')
      expect(phrases).to include(phrase)
    end
  end
end
