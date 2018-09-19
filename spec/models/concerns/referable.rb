require 'rails_helper'

shared_examples_for 'has references for' do |*topics|
  let(:model) { described_class }
  let(:item) { FactoryGirl.build(model.to_s.underscore.to_sym) }

  topics.each do |topic|
    it(topic) do
      accessor = "#{topic}_references"
      expect(item).to respond_to(accessor)
      url, description = Faker::Internet.url, Faker::Lorem.sentence
      item.send(accessor).clear
      item.send(accessor).build(url: url, description: description)
      expect { item.save(validate: false) }.to change {
        Reference.where(referer_type: described_class, group: topic).count
      }.by(1)
    end
  end
end
