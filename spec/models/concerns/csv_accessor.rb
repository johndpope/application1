require 'rails_helper'

shared_examples_for 'has CSV accessors for' do |*attributes|
  let(:model) { described_class }
  let(:item) { FactoryGirl.build(model.to_s.underscore.to_sym) }

  attributes.each do |attribute|
    it("##{attribute}") do
      item.send("#{attribute}=", ['One', 'Two', 'Fourty Two'])
      expect(item.send("#{attribute}_csv")).to eq('One, Two, Fourty Two')
      item.send("#{attribute}_csv=", 'Nine, One,One')
      expect(item.send(attribute)).to eq(['Nine', 'One', 'One'])
    end
  end
end
